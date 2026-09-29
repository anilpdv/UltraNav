import Foundation
@testable import UltraNav

actor FakeRouteStore: RouteStoring {
    private var routes: [Route.ID: Route]
    var shouldFailLoad: Bool = false
    var shouldFailSave: Bool = false
    var shouldFailDelete: Bool = false

    init(routes: [Route] = []) {
        self.routes = Dictionary(
            uniqueKeysWithValues: routes.map { ($0.id, $0) }
        )
    }

    func listRoutes() async throws -> [RouteSummary] {
        routes.values.map { RouteSummary(from: $0) }
    }

    func loadRoute(id: Route.ID) async throws -> Route {
        if shouldFailLoad {
            throw RouteStoreError.readFailed("Simulated read failure")
        }
        guard let route = routes[id] else {
            throw RouteStoreError.routeNotFound(id)
        }
        return route
    }

    func saveRoute(_ route: Route, behavior: RouteSaveBehavior) async throws -> RouteSaveOutcome {
        if shouldFailSave {
            throw RouteStoreError.writeFailed("Simulated write failure")
        }
        let exists = routes[route.id] != nil
        if exists && behavior == .failIfExists {
            throw RouteStoreError.duplicateRoute(route.id)
        }
        routes[route.id] = route
        return exists ? .overwritten : .savedNew
    }

    func deleteRoute(id: Route.ID, activeRouteID: Route.ID?) async throws {
        if shouldFailDelete {
            throw RouteStoreError.deleteFailed("Simulated delete failure")
        }
        if let active = activeRouteID, active == id {
            throw RouteStoreError.activeRouteProtected(id)
        }
        guard routes.removeValue(forKey: id) != nil else {
            throw RouteStoreError.routeNotFound(id)
        }
    }

    func routeExists(id: Route.ID) async -> Bool {
        routes[id] != nil
    }
}
