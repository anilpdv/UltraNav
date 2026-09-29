import Foundation

/// Formal storage contract for persisting, listing, loading, and deleting routes.
public protocol RouteStoring: Sendable {
    func listRoutes() async throws -> [RouteSummary]
    func loadRoute(id: Route.ID) async throws -> Route
    func saveRoute(_ route: Route, behavior: RouteSaveBehavior) async throws -> RouteSaveOutcome
    func deleteRoute(id: Route.ID, activeRouteID: Route.ID?) async throws
    func routeExists(id: Route.ID) async -> Bool
}

public extension RouteStoring {
    func saveRoute(_ route: Route) async throws {
        _ = try await saveRoute(route, behavior: .overwriteExisting)
    }

    func deleteRoute(id: Route.ID) async throws {
        try await deleteRoute(id: id, activeRouteID: nil)
    }
}
