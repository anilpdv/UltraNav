import Foundation

/// Deterministic, segment-projecting route matcher with spatial indexing and multi-factor continuity scoring.
public struct RouteMatcher: RouteMatching, Sendable {
    public let configuration: RouteMatchingConfiguration
    private let projector: RouteSegmentProjector

    public init(
        configuration: RouteMatchingConfiguration = .standard,
        projector: RouteSegmentProjector = RouteSegmentProjector()
    ) {
        self.configuration = configuration
        self.projector = projector
    }

    public func match(
        location: LocationSample,
        route: Route,
        previousMatch: RouteMatch?
    ) throws -> RouteMatch? {
        guard route.points.count >= 2 else {
            return nil
        }

        let geometryIndex = RouteGeometryIndex(route: route)
        return match(
            location: location,
            geometryIndex: geometryIndex,
            previousMatch: previousMatch
        )
    }

    /// Matches a location sample against a pre-indexed route geometry.
    public func match(
        location: LocationSample,
        geometryIndex: RouteGeometryIndex,
        previousMatch: RouteMatch?
    ) -> RouteMatch? {
        guard !geometryIndex.edges.isEmpty else {
            return nil
        }

        let candidates = geometryIndex.candidateEdges(
            near: location.coordinate,
            searchRadiusMeters: configuration.searchRadiusMeters,
            previousEdgeIndex: previousMatch?.segmentIndex,
            forwardWindow: configuration.forwardCandidateWindow,
            backwardWindow: configuration.backwardCandidateWindow
        )

        guard !candidates.isEmpty else {
            return nil
        }

        struct ScoredCandidate {
            let edge: RouteGeometryEdge
            let projection: SegmentProjectionResult
            let headingDeltaDegrees: Double?
            let score: Double
        }

        var scoredCandidates: [ScoredCandidate] = []

        let userSpeed = location.speedMetersPerSecond ?? 0.0
        let isSpeedRelevant = userSpeed >= configuration.headingRelevanceSpeedThresholdMetersPerSecond
        let userCourse = (isSpeedRelevant ? location.courseDegrees : nil)

        for edge in candidates {
            let proj = projector.project(coordinate: location.coordinate, onto: edge)

            // 1. Cross-Track component
            let crossTrackCost = proj.crossTrackDistanceMeters * configuration.crossTrackWeight

            // 2. Heading alignment component
            var headingDelta: Double? = nil
            var headingCost: Double = 0.0
            if let course = userCourse {
                var diff = abs(course - edge.bearingDegrees).truncatingRemainder(dividingBy: 360.0)
                if diff > 180.0 { diff = 360.0 - diff }
                headingDelta = diff
                headingCost = diff * configuration.headingWeight
            }

            // 3. Progress continuity penalty
            var continuityCost: Double = 0.0
            if let prev = previousMatch {
                let deltaDistance = proj.distanceAlongRouteMeters - prev.distanceAlongRouteMeters
                if deltaDistance < -2.0 {
                    // Backwards movement penalty
                    continuityCost += abs(deltaDistance) * configuration.backwardProgressPenaltyPerMeter
                } else if deltaDistance > 120.0 {
                    // Forward jump penalty
                    continuityCost += (deltaDistance - 120.0) * configuration.forwardJumpPenaltyPerMeter
                }
            }

            let totalScore = crossTrackCost + headingCost + continuityCost

            scoredCandidates.append(
                ScoredCandidate(
                    edge: edge,
                    projection: proj,
                    headingDeltaDegrees: headingDelta,
                    score: totalScore
                )
            )
        }

        // Sort by score ascending (lowest cost is best match)
        scoredCandidates.sort { $0.score < $1.score }

        guard let best = scoredCandidates.first else {
            return nil
        }

        // 4. Confidence evaluation
        let confidence: RouteMatchingConfidence
        if scoredCandidates.count > 1 {
            let secondBest = scoredCandidates[1]
            let scoreDiff = secondBest.score - best.score
            let distDiff = abs(secondBest.projection.distanceAlongRouteMeters - best.projection.distanceAlongRouteMeters)

            if scoreDiff < 5.0 && distDiff > 50.0 {
                confidence = .ambiguous
            } else if best.projection.crossTrackDistanceMeters <= 15.0 {
                confidence = .high
            } else if best.projection.crossTrackDistanceMeters <= 35.0 {
                confidence = .medium
            } else {
                confidence = .low
            }
        } else {
            if best.projection.crossTrackDistanceMeters <= 15.0 {
                confidence = .high
            } else if best.projection.crossTrackDistanceMeters <= 35.0 {
                confidence = .medium
            } else {
                confidence = .low
            }
        }

        return RouteMatch(
            matchedCoordinate: best.projection.projectedCoordinate,
            segmentIndex: best.edge.index,
            segmentFraction: best.projection.fraction,
            distanceAlongRouteMeters: best.projection.distanceAlongRouteMeters,
            crossTrackDistanceMeters: best.projection.crossTrackDistanceMeters,
            headingDifferenceDegrees: best.headingDeltaDegrees,
            confidence: confidence
        )
    }
}
