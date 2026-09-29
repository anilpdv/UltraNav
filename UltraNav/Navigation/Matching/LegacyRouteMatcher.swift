import Foundation

struct LegacyRouteMatcher: RouteMatching, Sendable {
    func match(
        location: LocationSample,
        route: Route,
        previousMatch: RouteMatch?
    ) throws -> RouteMatch? {
        guard !route.points.isEmpty else {
            return nil
        }

        // Find nearest route point (legacy vertex matching)
        // TODO(PHASE-5): Replace with bounded segment projection, progress-aware candidate search, and intersection handling.
        var minDistance: Double = .infinity
        var closestIndex = 0

        for (idx, pt) in route.points.enumerated() {
            let dist = location.coordinate.distance(to: pt.coordinate)
            if dist < minDistance {
                minDistance = dist
                closestIndex = idx
            }
        }

        let matchedPoint = route.points[closestIndex]
        let userProgressDist = matchedPoint.cumulativeDistanceMeters

        return RouteMatch(
            matchedCoordinate: matchedPoint.coordinate,
            segmentIndex: closestIndex,
            segmentFraction: 0,
            distanceAlongRouteMeters: userProgressDist,
            crossTrackDistanceMeters: minDistance,
            headingDifferenceDegrees: nil
        )
    }
}
