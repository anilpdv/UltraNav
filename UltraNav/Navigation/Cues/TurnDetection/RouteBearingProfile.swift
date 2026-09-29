import Foundation

/// Models a continuous profile of route edge bearings across cumulative distances.
struct RouteBearingProfile: Sendable {
    struct Sample: Sendable {
        let startDistanceMeters: Double
        let endDistanceMeters: Double
        let startCoordinate: Coordinate
        let endCoordinate: Coordinate
        let bearingDegrees: Double
        let lengthMeters: Double

        var midpointDistanceMeters: Double {
            startDistanceMeters + lengthMeters / 2.0
        }
    }

    let samples: [Sample]
    let totalDistanceMeters: Double

    init(route: Route) {
        var precomputed: [Sample] = []
        var runningDistance: Double = 0.0

        let segments = route.segments.isEmpty && !route.points.isEmpty
            ? [RouteSegment(segmentIndex: 0, startPointIndex: 0, endPointIndex: max(0, route.points.count - 1), distanceMeters: route.totalDistanceMeters)]
            : route.segments

        for segment in segments {
            let startIdx = segment.startPointIndex
            let endIdx = segment.endPointIndex
            guard startIdx < endIdx, endIdx < route.points.count else { continue }

            for i in startIdx..<endIdx {
                let p1 = route.points[i]
                let p2 = route.points[i + 1]
                let dist = p1.coordinate.distance(to: p2.coordinate)
                let bearing = p1.coordinate.initialBearing(to: p2.coordinate)

                precomputed.append(
                    Sample(
                        startDistanceMeters: runningDistance,
                        endDistanceMeters: runningDistance + dist,
                        startCoordinate: p1.coordinate,
                        endCoordinate: p2.coordinate,
                        bearingDegrees: bearing,
                        lengthMeters: dist
                    )
                )
                runningDistance += dist
            }
        }

        self.samples = precomputed
        self.totalDistanceMeters = runningDistance > 0 ? runningDistance : route.totalDistanceMeters
    }

    /// Finds the coordinate at a specific along-track distance.
    func coordinate(at distanceMeters: Double) -> Coordinate? {
        guard !samples.isEmpty else { return nil }
        let clampedDist = max(0.0, min(totalDistanceMeters, distanceMeters))

        guard let sample = samples.first(where: { clampedDist >= $0.startDistanceMeters && clampedDist <= $0.endDistanceMeters }) else {
            return samples.last?.endCoordinate
        }

        guard sample.lengthMeters > 0.0001 else { return sample.startCoordinate }
        let fraction = (clampedDist - sample.startDistanceMeters) / sample.lengthMeters
        let lat = sample.startCoordinate.latitude + fraction * (sample.endCoordinate.latitude - sample.startCoordinate.latitude)
        let lon = sample.startCoordinate.longitude + fraction * (sample.endCoordinate.longitude - sample.startCoordinate.longitude)
        return Coordinate(latitude: lat, longitude: lon)
    }

    /// Computes the weighted average entry bearing approaching a given along-track distance over a distance window.
    func entryBearing(at distanceMeters: Double, windowMeters: Double = 25.0) -> Double? {
        let startDist = max(0.0, distanceMeters - windowMeters)
        let relevantSamples = samples.filter { $0.endDistanceMeters > startDist && $0.startDistanceMeters < distanceMeters }
        guard !relevantSamples.isEmpty else { return nil }

        return weightedAverageBearing(samples: relevantSamples, rangeStart: startDist, rangeEnd: distanceMeters)
    }

    /// Computes the weighted average exit bearing departing from a given along-track distance over a distance window.
    func exitBearing(at distanceMeters: Double, windowMeters: Double = 25.0) -> Double? {
        let endDist = min(totalDistanceMeters, distanceMeters + windowMeters)
        let relevantSamples = samples.filter { $0.endDistanceMeters > distanceMeters && $0.startDistanceMeters < endDist }
        guard !relevantSamples.isEmpty else { return nil }

        return weightedAverageBearing(samples: relevantSamples, rangeStart: distanceMeters, rangeEnd: endDist)
    }

    /// Computes the signed turn angle (exitBearing - entryBearing) in degrees [-180, 180) at a specific route distance.
    func turnAngle(at distanceMeters: Double, windowMeters: Double = 25.0) -> Double? {
        guard let entry = entryBearing(at: distanceMeters, windowMeters: windowMeters),
              let exit = exitBearing(at: distanceMeters, windowMeters: windowMeters) else {
            return nil
        }
        return ManeuverClassifier.normalizeAngleDifference(exit - entry)
    }

    private func weightedAverageBearing(samples: [Sample], rangeStart: Double, rangeEnd: Double) -> Double {
        var sinSum: Double = 0.0
        var cosSum: Double = 0.0
        var totalWeight: Double = 0.0

        for sample in samples {
            let overlapStart = max(sample.startDistanceMeters, rangeStart)
            let overlapEnd = min(sample.endDistanceMeters, rangeEnd)
            let weight = max(0.0, overlapEnd - overlapStart)

            if weight > 0 {
                let rad = sample.bearingDegrees * .pi / 180.0
                sinSum += sin(rad) * weight
                cosSum += cos(rad) * weight
                totalWeight += weight
            }
        }

        guard totalWeight > 0 else { return samples.first?.bearingDegrees ?? 0.0 }
        let avgRad = atan2(sinSum, cosSum)
        var avgDeg = avgRad * 180.0 / .pi
        if avgDeg < 0 { avgDeg += 360.0 }
        return avgDeg
    }
}
