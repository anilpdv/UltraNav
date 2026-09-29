import Foundation
@testable import UltraNav

actor FakeRouteStore: RouteStoring {
    enum Call: Equatable, Sendable {
        case listRoutes
        case loadRoute(Route.ID)
        case saveRoute(Route.ID, RouteSaveBehavior)
        case deleteRoute(Route.ID)
        case routeExists(Route.ID)
    }

    private(set) var calls: [Call] = []
    private var routes: [Route.ID: Route]

    var shouldFailLoad: Bool = false
    var shouldFailSave: Bool = false
    var shouldFailDelete: Bool = false
    var loadGate: OperationGate?

    init(routes: [Route] = []) {
        self.routes = Dictionary(
            uniqueKeysWithValues: routes.map { ($0.id, $0) }
        )
    }

    func setLoadGate(_ gate: OperationGate?) {
        self.loadGate = gate
    }

    func listRoutes() async throws -> [RouteSummary] {
        calls.append(.listRoutes)
        let summaries = routes.values.map { RouteSummary(from: $0) }
        // Deterministic sort: createdAt descending, then name, then ID
        return summaries.sorted { a, b in
            let dateA = a.createdAt ?? Date.distantPast
            let dateB = b.createdAt ?? Date.distantPast
            if dateA != dateB {
                return dateA > dateB
            }
            if a.name != b.name {
                return a.name < b.name
            }
            return a.id.rawValue < b.id.rawValue
        }
    }

    func loadRoute(id: Route.ID) async throws -> Route {
        calls.append(.loadRoute(id))

        if let gate = loadGate {
            try await gate.wait()
        }

        if shouldFailLoad {
            throw RouteStoreError.readFailed("Simulated read failure")
        }
        guard let route = routes[id] else {
            throw RouteStoreError.routeNotFound(id)
        }
        return route
    }

    func saveRoute(_ route: Route, behavior: RouteSaveBehavior) async throws -> RouteSaveOutcome {
        calls.append(.saveRoute(route.id, behavior))
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
        calls.append(.deleteRoute(id))
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
        calls.append(.routeExists(id))
        return routes[id] != nil
    }

    func clear() {
        calls.removeAll()
        routes.removeAll()
        shouldFailLoad = false
        shouldFailSave = false
        shouldFailDelete = false
        loadGate = nil
    }
}
