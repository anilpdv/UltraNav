import Foundation

/// Value type emitted by RouteLibraryEngine capturing the complete UI-visible state of the route library.
public struct RouteLibrarySnapshot: Equatable, Sendable {
    public let state: RouteLibraryState
    public let routes: [RouteSummary]
    public let selectedRouteID: Route.ID?
    public let activeRouteID: Route.ID?
    public let failure: RouteLibraryFailure?

    public init(
        state: RouteLibraryState = .idle,
        routes: [RouteSummary] = [],
        selectedRouteID: Route.ID? = nil,
        activeRouteID: Route.ID? = nil,
        failure: RouteLibraryFailure? = nil
    ) {
        self.state = state
        self.routes = routes
        self.selectedRouteID = selectedRouteID
        self.activeRouteID = activeRouteID
        self.failure = failure
    }

    public static let initial = RouteLibrarySnapshot(
        state: .idle,
        routes: [],
        selectedRouteID: nil,
        activeRouteID: nil,
        failure: nil
    )
}
