import Foundation

protocol RouteCompletionEvaluating: Sendable {
    func isRouteCompleted(
        route: Route,
        match: RouteMatch,
        location: LocationSample
    ) -> Bool
}
