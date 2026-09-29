import Foundation

/// Pure deterministic normalizer that converts GPX parsed documents into normalized domain Routes.
public final class RouteNormalizer: RouteNormalizing, Sendable {
    private let distanceCalculator: any CoordinateDistanceCalculating
    private let identityCreator: any RouteIdentityCreating
    private let contentSelector: any GPXContentSelecting

    public init(
        distanceCalculator: any CoordinateDistanceCalculating = CoreLocationDistanceCalculator(),
        identityCreator: any RouteIdentityCreating = SHA256RouteIdentityCreator(),
        contentSelector: any GPXContentSelecting = StandardGPXContentSelector()
    ) {
        self.distanceCalculator = distanceCalculator
        self.identityCreator = identityCreator
        self.contentSelector = contentSelector
    }

    public func normalize(
        document: GPXParsedDocument,
        source: RouteSource,
        fallbackName: String,
        policy: RouteNormalizationPolicy = .default
    ) throws -> RouteNormalizationResult {
        var warnings: [RouteNormalizationWarning] = []

        // 1. Content Selection
        let selection = try contentSelector.selectContent(
            from: document,
            policy: policy.contentSelectionPolicy
        )
        for warnStr in selection.warnings {
            warnings.append(.contentSelectionWarning(warnStr))
        }

        let rawSegments = selection.segments.map { $0.points }.filter { !$0.isEmpty }
        guard !rawSegments.isEmpty else {
            throw RouteNormalizationFailure.noPointsRemainingAfterFiltering
        }

        let totalOriginalPoints = rawSegments.reduce(0) { $0 + $1.count }

        // 2. Process segments, apply duplicate policy, and calculate cumulative distances
        var normalizedPoints: [RoutePoint] = []
        var domainSegments: [RouteSegment] = []
        var segmentBreaks: [Int] = []
        var cumulativeDistance: Double = 0.0

        var totalAscent: Double = 0.0
        var totalDescent: Double = 0.0
        var minEle: Double = .infinity
        var maxEle: Double = -.infinity
        var hasAnyElevation = false
        var duplicateFilteredCount = 0
        var missingEleCount = 0
        var clampedNegativeEleCount = 0

        var minLat: Double = .infinity
        var maxLat: Double = -.infinity
        var minLon: Double = .infinity
        var maxLon: Double = -.infinity
        var crossesAntimeridian = false
        var previousPointLongitude: Double?

        for (segmentIdx, rawPts) in rawSegments.enumerated() {
            guard !rawPts.isEmpty else { continue }

            let segmentStartIndex = normalizedPoints.count
            let segmentStartDistance = cumulativeDistance
            var lastSegmentPoint: RoutePoint?

            for pt in rawPts {
                // Check duplicate policy
                if let prev = lastSegmentPoint {
                    let isDuplicateCoord = (pt.latitude == prev.coordinate.latitude && pt.longitude == prev.coordinate.longitude)
                    let isDuplicateEle = (pt.elevationMeters == prev.elevationMeters)
                    let isDuplicateTime = (pt.timestamp == prev.timestamp)

                    switch policy.duplicatePointPolicy {
                    case .preserveAll:
                        break

                    case .removeExactConsecutiveCoordinates:
                        if isDuplicateCoord {
                            duplicateFilteredCount += 1
                            continue
                        }

                    case .removeExactConsecutiveSamples:
                        if isDuplicateCoord && isDuplicateEle && isDuplicateTime {
                            duplicateFilteredCount += 1
                            continue
                        }

                    case .removeNearDuplicates(let threshold):
                        let dist = distanceCalculator.distance(from: prev.coordinate, to: Coordinate(latitude: pt.latitude, longitude: pt.longitude))
                        if dist < threshold {
                            duplicateFilteredCount += 1
                            continue
                        }
                    }
                }

                // Elevation processing
                var elevation = pt.elevationMeters
                if let ele = elevation {
                    hasAnyElevation = true
                    if ele < 0.0 && policy.clampNegativeElevationToZero {
                        elevation = 0.0
                        clampedNegativeEleCount += 1
                    }
                    if let eleVal = elevation {
                        minEle = min(minEle, eleVal)
                        maxEle = max(maxEle, eleVal)

                        if let prevEle = lastSegmentPoint?.elevationMeters {
                            let dEle = eleVal - prevEle
                            if abs(dEle) >= policy.elevationNoiseThresholdMeters {
                                if dEle > 0 {
                                    totalAscent += dEle
                                } else {
                                    totalDescent += abs(dEle)
                                }
                            }
                        }
                    }
                } else {
                    missingEleCount += 1
                }

                // Coordinate & Antimeridian check
                let coord = Coordinate(latitude: pt.latitude, longitude: pt.longitude)
                minLat = min(minLat, pt.latitude)
                maxLat = max(maxLat, pt.latitude)
                minLon = min(minLon, pt.longitude)
                maxLon = max(maxLon, pt.longitude)

                if let prevLon = previousPointLongitude {
                    if abs(pt.longitude - prevLon) > 180.0 {
                        crossesAntimeridian = true
                    }
                }
                previousPointLongitude = pt.longitude

                // Calculate distance within segment
                if let prev = lastSegmentPoint {
                    let delta = distanceCalculator.distance(from: prev.coordinate, to: coord)
                    guard delta.isFinite && !delta.isNaN && delta >= 0 else {
                        throw RouteNormalizationFailure.nonFiniteDistanceDelta(
                            segmentIndex: segmentIdx,
                            pointIndex: normalizedPoints.count
                        )
                    }

                    if delta > policy.maximumGapDistanceMeters {
                        warnings.append(.largePointGapDetected(distanceMeters: delta))
                    }

                    cumulativeDistance += delta
                }

                let routePoint = RoutePoint(
                    coordinate: coord,
                    elevationMeters: elevation,
                    timestamp: pt.timestamp,
                    cumulativeDistanceMeters: cumulativeDistance
                )
                normalizedPoints.append(routePoint)
                lastSegmentPoint = routePoint
            }

            let segmentEndIndex = normalizedPoints.count - 1
            if segmentEndIndex >= segmentStartIndex {
                let segmentID = UUID()
                let segment = RouteSegment(
                    id: segmentID,
                    startPointIndex: segmentStartIndex,
                    endPointIndex: segmentEndIndex,
                    startDistanceMeters: segmentStartDistance,
                    endDistanceMeters: cumulativeDistance
                )
                domainSegments.append(segment)
                segmentBreaks.append(segmentEndIndex)
            }
        }

        guard normalizedPoints.count >= 2 else {
            throw RouteNormalizationFailure.noPointsRemainingAfterFiltering
        }

        if duplicateFilteredCount > 0 {
            warnings.append(.duplicatePointsFiltered(count: duplicateFilteredCount))
        }
        if missingEleCount > 0 {
            warnings.append(.missingElevationDetected(count: missingEleCount))
        }
        if clampedNegativeEleCount > 0 {
            warnings.append(.negativeElevationClamped(count: clampedNegativeEleCount))
        }
        if crossesAntimeridian {
            warnings.append(.antimeridianCrossingDetected)
        }
        if rawSegments.count > 1 {
            warnings.append(.disconnectedSegmentsDetected(gapMeters: 0.0))
        }

        // 3. Normalize Waypoints
        var domainWaypoints: [RouteWaypoint] = []
        for wpt in selection.waypoints {
            let coord = Coordinate(latitude: wpt.latitude, longitude: wpt.longitude)
            domainWaypoints.append(RouteWaypoint(
                id: UUID(),
                coordinate: coord,
                name: wpt.name ?? "Waypoint",
                description: wpt.description,
                symbol: wpt.symbol,
                elevationMeters: wpt.elevationMeters
            ))
        }

        // 4. Calculate Bounds
        let bounds = RouteBounds(
            minimumLatitude: minLat,
            maximumLatitude: maxLat,
            minimumLongitude: minLon,
            maximumLongitude: maxLon
        )

        // 5. Compute Deterministic Route Identity & Fingerprints
        let coords = normalizedPoints.map { $0.coordinate }
        let routeID = identityCreator.makeRouteID(
            points: coords,
            segmentBreaks: segmentBreaks,
            version: policy.version
        )

        // 6. Assemble Metadata with Precedence
        let chosenName = selection.selectedName
            ?? document.metadata.name
            ?? (fallbackName.isEmpty ? "Imported Route" : fallbackName)

        let chosenDescription = selection.selectedDescription
            ?? document.metadata.description

        let routeMetadata = RouteMetadata(
            name: chosenName,
            description: chosenDescription,
            source: source,
            importedAt: Date(),
            originalCreatedAt: document.metadata.time
        )

        // 7. Assemble Canonical Route
        let canonicalRoute = Route(
            id: routeID,
            metadata: routeMetadata,
            points: normalizedPoints,
            segments: domainSegments,
            waypoints: domainWaypoints,
            bounds: bounds,
            totalDistanceMeters: cumulativeDistance,
            totalAscentMeters: hasAnyElevation ? totalAscent : 0.0,
            totalDescentMeters: hasAnyElevation ? totalDescent : 0.0,
            minimumElevationMeters: hasAnyElevation ? minEle : nil,
            maximumElevationMeters: hasAnyElevation ? maxEle : nil
        )

        return RouteNormalizationResult(
            route: canonicalRoute,
            warnings: warnings
        )
    }
}
