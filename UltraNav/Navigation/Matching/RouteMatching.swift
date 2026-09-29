import Foundation

protocol RouteMatching: Sendable {
    func match(
        location: LocationSample,
        route: Route,
        previousMatch: RouteMatch?
    ) throws -> RouteMatch?
}
