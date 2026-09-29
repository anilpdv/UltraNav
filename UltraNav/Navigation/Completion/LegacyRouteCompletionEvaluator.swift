import Foundation

struct LegacyRouteCompletionEvaluator: RouteCompletionEvaluating, Sendable {
    let completionThresholdMeters: Double

    init(completionThresholdMeters: Double = 30.0) {
        self.completionThresholdMeters = completionThresholdMeters
    }

    func isRouteCompleted(
        route: Route,
        match: RouteMatch,
        location: LocationSample
    ) -> Bool {
        guard let lastPoint = route.points.last else {
            return false
        }

        let remaining = max(0, route.totalDistanceMeters - match.distanceAlongRouteMeters)
        let distanceToEndPoint = location.coordinate.distance(to: lastPoint.coordinate)

        // Completed if remaining distance along route is within threshold or proximity to destination is reached
        // TODO(PHASE-7): Improve completion detection with arrival gates and bearing alignment
        return remaining <= completionThresholdMeters || distanceToEndPoint <= completionThresholdMeters
    }
}
