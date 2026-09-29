import Foundation

/// Pure deterministic normalizer that converts GPX parsed documents into normalized domain Routes.
public final class RouteNormalizer: RouteNormalizing, Sendable {
    private let distanceCalculator: any CoordinateDistanceCalculating
    private let identityCreator: any RouteIdentityCreating

    public init(
        distanceCalculator: any CoordinateDistanceCalculating = CoreLocationDistanceCalculator(),
        identityCreator: any RouteIdentityCreating = SHA256RouteIdentityCreator()
    ) {
        self.distanceCalculator = distanceCalculator
        self.identityCreator = identityCreator
    }

    public func normalize(
        document: GPXParsedDocument,
        source: RouteSource,
        fallbackName: String,
        policy: RouteNormalizationPolicy = .default
    ) throws -> RouteNormalizationResult {
        var warnings: [RouteNormalizationWarning] = []

        // 1. Determine raw segments from tracks or fallback routes
        var rawSegments: [[GPXParsedPoint]] = []
        for track in document.tracks {
            for segment in track.segments where !segment.points.isEmpty {
                rawSegments.append(segment.points)
            }
        }

        if rawSegments.isEmpty {
            for route in document.routes where !route.points.isEmpty {
                rawSegments.append(route.points)
            }
            if !rawSegments.isEmpty {
                warnings.append(.fallbackRoutePointsUsed)
            }
        }

        guard !rawSegments.isEmpty else {
            throw RouteNormalizationFailure.noPointsRemainingAfterFiltering
        }

        // 2. Process segments and points
        var normalizedPoints: [RoutePoint] = []
        var segments: [RouteSegment] = []
        var segmentBreaks: [Int] = []
        var cumulativeDistance: Double = 0.0

        var totalAscent: Double = 0.0
        var totalDescent: Double = 0.0
        var minEle: Double = .infinity
        var maxEle: Double = -.infinity
        var hasAnyElevation = false
        var duplicateFilteredCount = 0

        for (segmentIdx, rawPts) in rawSegments.enumerated() {
            guard !rawPts.isEmpty else { continue }

            let segmentStartIndex = normalizedPoints.count
            var segmentDistance: Double = 0.0
            var lastSegmentCoord: Coordinate?
            var lastSegmentEle: Double?

            for (ptIdx, rawPt) in rawPts.enumerated() {
                let coord = Coordinate(latitude: rawPt.latitude, longitude: rawPt.longitude)
                var ele = rawPt.elevation

                if let e = ele {
                    hasAnyElevation = true
                    if policy.clampNegativeElevationToZero && e < 0 {
                        ele = 0
                        warnings.append(.negativeElevationClamped(count: 1))
                    }
                }

                // Check distance from previous point in the SAME segment
                if let lastCoord = lastSegmentCoord {
                    let dDist = distanceCalculator.distance(from: lastCoord, to: coord)
                    let isLastPointInSegment = (ptIdx == rawPts.count - 1)

                    // Spacing filter: Skip internal points that are too close to predecessor
                    if dDist < policy.minimumPointSpacingMeters && !isLastPointInSegment {
                        duplicateFilteredCount += 1
                        continue
                    }

                    segmentDistance += dDist
                    cumulativeDistance += dDist

                    // Elevation gain / loss calculation
                    if let e1 = lastSegmentEle, let e2 = ele {
                        let dEle = e2 - e1
                        if dEle > policy.elevationNoiseThresholdMeters {
                            totalAscent += dEle
                        } else if dEle < -policy.elevationNoiseThresholdMeters {
                            totalDescent += abs(dEle)
                        }
                    }
                }

                if let e = ele {
                    if e < minEle { minEle = e }
                    if e > maxEle { maxEle = e }
                }

                let routePoint = RoutePoint(
                    coordinate: coord,
                    elevationMeters: ele,
                    timestamp: rawPt.time,
                    cumulativeDistanceMeters: cumulativeDistance
                )
                normalizedPoints.append(routePoint)

                lastSegmentCoord = coord
                lastSegmentEle = ele
            }

            let segmentEndIndex = max(segmentStartIndex, normalizedPoints.count - 1)
            let routeSegment = RouteSegment(
                segmentIndex: segmentIdx,
                startPointIndex: segmentStartIndex,
                endPointIndex: segmentEndIndex,
                distanceMeters: segmentDistance
            )
            segments.append(routeSegment)
            segmentBreaks.append(segmentEndIndex)
        }

        if duplicateFilteredCount > 0 {
            warnings.append(.duplicatePointsFiltered(count: duplicateFilteredCount))
        }

        guard !normalizedPoints.isEmpty else {
            throw RouteNormalizationFailure.noPointsRemainingAfterFiltering
        }

        // 3. Extract waypoints
        var routeWaypoints: [RouteWaypoint] = []
        for wpt in document.waypoints {
            let wpCoord = Coordinate(latitude: wpt.latitude, longitude: wpt.longitude)
            routeWaypoints.append(RouteWaypoint(
                coordinate: wpCoord,
                name: wpt.name ?? "Waypoint",
                description: wpt.description,
                symbol: wpt.symbol,
                elevationMeters: wpt.elevation
            ))
        }

        // 4. Derive metadata name & description
        let resolvedName: String = {
            if let metaName = document.metadata.name, !metaName.isEmpty { return metaName }
            if let trkName = document.tracks.first?.name, !trkName.isEmpty { return trkName }
            if let rteName = document.routes.first?.name, !rteName.isEmpty { return rteName }
            return fallbackName
        }()

        let resolvedDesc: String? = {
            if let metaDesc = document.metadata.description, !metaDesc.isEmpty { return metaDesc }
            if let trkDesc = document.tracks.first?.description, !trkDesc.isEmpty { return trkDesc }
            if let rteDesc = document.routes.first?.description, !rteDesc.isEmpty { return rteDesc }
            return nil
        }()

        let metadata = RouteMetadata(
            name: resolvedName,
            description: resolvedDesc,
            source: source,
            importedAt: Date(),
            originalCreatedAt: document.metadata.time
        )

        // 5. Generate deterministic RouteID
        let coordinates = normalizedPoints.map { $0.coordinate }
        let routeID = identityCreator.makeRouteID(points: coordinates, segmentBreaks: segmentBreaks)

        let route = Route(
            id: routeID,
            metadata: metadata,
            points: normalizedPoints,
            segments: segments,
            waypoints: routeWaypoints,
            bounds: nil, // Auto-computed by Route init
            totalDistanceMeters: cumulativeDistance,
            totalAscentMeters: hasAnyElevation ? totalAscent : nil,
            totalDescentMeters: hasAnyElevation ? totalDescent : nil,
            minimumElevationMeters: hasAnyElevation && minEle != .infinity ? minEle : nil,
            maximumElevationMeters: hasAnyElevation && maxEle != -.infinity ? maxEle : nil
        )

        return RouteNormalizationResult(route: route, warnings: warnings)
    }
}
