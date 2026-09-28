import Foundation
@testable import UltraNav

actor FakeRouteStore: RouteStoring {
    private var routes: [Route.ID: Route]

    init(routes: [Route] = []) {
        self.routes = Dictionary(
            uniqueKeysWithValues: routes.map { ($0.id, $0) }
        )
    }

    func listRoutes() async throws -> [RouteSummary] {
        routes.values.map { route in
            RouteSummary(
                id: route.id,
                name: route.metadata.name,
                totalDistanceMeters: route.totalDistanceMeters,
                pointCount: route.points.count,
                createdAt: route.metadata.createdAt
            )
        }
    }

    func loadRoute(id: Route.ID) async throws -> Route {
        guard let route = routes[id] else {
            throw RouteStoreError.routeNotFound
        }
        return route
    }

    func saveRoute(_ route: Route) async throws {
        routes[route.id] = route
    }

    func deleteRoute(id: Route.ID) async throws {
        guard routes.removeValue(forKey: id) != nil else {
            throw RouteStoreError.routeNotFound
        }
    }

    func routeExists(id: Route.ID) async -> Bool {
        routes[id] != nil
    }
}
