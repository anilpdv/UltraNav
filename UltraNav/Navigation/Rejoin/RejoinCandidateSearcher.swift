import Foundation

/// Searches and ranks prospective rejoin candidates across the route geometry.
actor RejoinCandidateSearcher: RejoinCandidateSearching {
    private let projector: RouteSegmentProjector

    init(projector: RouteSegmentProjector = RouteSegmentProjector()) {
        self.projector = projector
    }

    func candidates(
        index: RouteGeometryIndex,
        context: RejoinSearchContext,
        configuration: RejoinConfiguration
    ) async throws -> [RejoinCandidate] {
        guard !index.edges.isEmpty else { return [] }

        let lastStableDistance = context.lastStableMatch?.distanceAlongRouteMeters ?? 0.0
        let coord = context.currentLocation.sample.coordinate

        // Stage 1: Search edges near last stable distance and local spatial radius
        let searchRadius = configuration.maximumCandidateCrossTrackMeters
        var candidateEdges = index.candidateEdges(
            near: coord,
            searchRadiusMeters: searchRadius,
            previousEdgeIndex: context.lastStableMatch?.segmentIndex
        )

        // Stage 2: Filter and deduplicate
        var uniqueEdgeDict: [Int: RouteGeometryEdge] = [:]
        for edge in candidateEdges {
            uniqueEdgeDict[edge.index] = edge
        }

        // Also ensure near-progress distance edges are included
        let minNearDist = max(0.0, lastStableDistance - configuration.nearProgressBackwardMeters)
        let maxNearDist = min(index.totalDistanceMeters, lastStableDistance + configuration.nearProgressForwardMeters)
        for edge in index.edges {
            if edge.endDistanceMeters >= minNearDist && edge.startDistanceMeters <= maxNearDist {
                uniqueEdgeDict[edge.index] = edge
            }
        }

        var edgesToEvaluate = Array(uniqueEdgeDict.values)

        // Stage 3: Project onto candidate edges
        var rawCandidates: [RejoinCandidate] = []
        for edge in edgesToEvaluate {
            let projection = projector.project(coordinate: coord, onto: edge)
            let crossTrack = projection.crossTrackDistanceMeters

            // Remove candidates beyond max cross-track unless expanding
            if crossTrack > configuration.maximumCandidateCrossTrackMeters * 1.5 {
                continue
            }

            let alongRoute = projection.distanceAlongRouteMeters
            let progressDelta = alongRoute - lastStableDistance

            // Heading difference calculation if moving with reliable course
            var headingDiff: Double? = nil
            var headingScore: Double? = nil
            if (context.currentLocation.sample.speedMetersPerSecond ?? 0.0) >= configuration.minimumSpeedForHeadingThresholdMetersPerSecond,
               let course = context.currentLocation.sample.courseDegrees {
                let edgeBearing = edge.bearingDegrees
                let diff = abs(course - edgeBearing).truncatingRemainder(dividingBy: 360.0)
                let normalizedDiff = diff > 180.0 ? 360.0 - diff : diff
                headingDiff = normalizedDiff
                headingScore = max(0.0, 1.0 - (normalizedDiff / 180.0))
            }

            // Proximity score [0.0 ... 1.0]
            let proximityScore = max(0.0, 1.0 - (crossTrack / configuration.maximumCandidateCrossTrackMeters))

            // Continuity score based on distance jump
            let absDelta = abs(progressDelta)
            let continuityScore: Double
            if absDelta <= 50.0 {
                continuityScore = 1.0
            } else if absDelta <= 200.0 {
                continuityScore = 0.8
            } else if absDelta <= 500.0 {
                continuityScore = 0.5
            } else if absDelta <= 1500.0 {
                continuityScore = 0.3
            } else {
                continuityScore = 0.1
            }

            // Forward preference score
            let forwardPreferenceScore: Double
            if progressDelta >= 0.0 && progressDelta <= configuration.nearProgressForwardMeters {
                forwardPreferenceScore = 1.0
            } else if progressDelta >= -configuration.nearProgressBackwardMeters && progressDelta < 0.0 {
                forwardPreferenceScore = 0.7
            } else if progressDelta < -configuration.nearProgressBackwardMeters {
                forwardPreferenceScore = 0.3
            } else {
                forwardPreferenceScore = 0.4
            }

            // Persistence score compared to previous candidate
            var persistenceScore = 0.0
            if let prev = context.previousCandidate {
                if prev.routeMatch.segmentIndex == edge.index ||
                   abs(alongRoute - prev.routeMatch.distanceAlongRouteMeters) <= configuration.candidatePersistenceDistanceMeters {
                    persistenceScore = 1.0
                }
            }

            // Calculate total weighted score
            let weights = configuration.scoringWeights
            let totalScore: Double
            if let hScore = headingScore {
                totalScore = (proximityScore * weights.proximity) +
                             (continuityScore * weights.continuity) +
                             (forwardPreferenceScore * weights.forwardPreference) +
                             (hScore * weights.heading) +
                             (persistenceScore * weights.persistence)
            } else {
                // Redistribute heading weight to proximity and continuity
                let extraProximity = weights.heading * (weights.proximity / (weights.proximity + weights.continuity))
                let extraContinuity = weights.heading * (weights.continuity / (weights.proximity + weights.continuity))
                totalScore = (proximityScore * (weights.proximity + extraProximity)) +
                             (continuityScore * (weights.continuity + extraContinuity)) +
                             (forwardPreferenceScore * weights.forwardPreference) +
                             (persistenceScore * weights.persistence)
            }

            // Confidence rating
            let confidence: RejoinConfidence
            if crossTrack <= 15.0 && totalScore >= 0.70 && (headingDiff == nil || headingDiff! <= configuration.maximumHeadingDifferenceDegrees) {
                confidence = .high
            } else if crossTrack <= configuration.maximumCandidateCrossTrackMeters && totalScore >= 0.45 {
                confidence = .medium
            } else {
                confidence = .low
            }

            let match = RouteMatch(
                matchedCoordinate: projection.projectedCoordinate,
                segmentIndex: edge.index,
                segmentFraction: projection.fraction,
                distanceAlongRouteMeters: alongRoute,
                crossTrackDistanceMeters: crossTrack,
                headingDifferenceDegrees: headingDiff,
                confidence: confidence == .high ? .high : (confidence == .medium ? .medium : .low)
            )

            let candidate = RejoinCandidate(
                routeMatch: match,
                progressDeltaFromLastStableMeters: progressDelta,
                crossTrackScore: proximityScore,
                continuityScore: continuityScore,
                headingScore: headingScore,
                forwardPreferenceScore: forwardPreferenceScore,
                ambiguityPenalty: 0.0,
                totalScore: totalScore,
                confidence: confidence,
                searchStrategy: absDelta <= configuration.nearProgressForwardMeters ? .nearLastStableProgress : .forwardBiasedSpatial
            )

            rawCandidates.append(candidate)
        }

        // Sort descending by total score, then lowest cross track
        rawCandidates.sort { (a, b) -> Bool in
            if abs(a.totalScore - b.totalScore) > 0.001 {
                return a.totalScore > b.totalScore
            }
            return a.routeMatch.crossTrackDistanceMeters < b.routeMatch.crossTrackDistanceMeters
        }

        // Detect ambiguity between top 2 candidates
        if rawCandidates.count >= 2 {
            let first = rawCandidates[0]
            let second = rawCandidates[1]
            let scoreDiff = first.totalScore - second.totalScore
            let distDiff = abs(first.routeMatch.distanceAlongRouteMeters - second.routeMatch.distanceAlongRouteMeters)

            if scoreDiff < configuration.ambiguityScoreThreshold && distDiff > 100.0 {
                // Ambiguity penalty applied to top candidate
                let penalizedFirst = RejoinCandidate(
                    routeMatch: first.routeMatch,
                    progressDeltaFromLastStableMeters: first.progressDeltaFromLastStableMeters,
                    crossTrackScore: first.crossTrackScore,
                    continuityScore: first.continuityScore,
                    headingScore: first.headingScore,
                    forwardPreferenceScore: first.forwardPreferenceScore,
                    ambiguityPenalty: configuration.ambiguityScoreThreshold - scoreDiff,
                    totalScore: max(0.0, first.totalScore - 0.2),
                    confidence: first.confidence == .high ? .medium : first.confidence,
                    searchStrategy: first.searchStrategy
                )
                rawCandidates[0] = penalizedFirst
            }
        }

        return rawCandidates
    }
}
