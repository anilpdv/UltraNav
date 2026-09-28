import Foundation

protocol RouteStoring: Sendable {
    func listRoutes() async throws
        -> [RouteSummary]

    func loadRoute(
        id: Route.ID
    ) async throws -> Route

    func saveRoute(
        _ route: Route
    ) async throws

    func deleteRoute(
        id: Route.ID
    ) async throws

    func routeExists(
        id: Route.ID
    ) async -> Bool
}
