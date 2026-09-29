import Foundation

@MainActor
final class RouteNavigationCoordinator {
    private let routeStore: any RouteStoring
    private let routeLibraryEngine: any RouteLibraryProviding
    private let navigationEngine: any NavigationEngineProviding
    private let climbEngine: any ClimbEngineProviding

    private var navigationSnapshotTask: Task<Void, Never>?
    private var routeLoadGeneration: Int = 0

    private(set) var isActive: Bool = false
    private(set) var activeRouteID: Route.ID?

    init(
        routeStore: any RouteStoring,
        routeLibraryEngine: any RouteLibraryProviding,
        navigationEngine: any NavigationEngineProviding,
        climbEngine: any ClimbEngineProviding
    ) {
        self.routeStore = routeStore
        self.routeLibraryEngine = routeLibraryEngine
        self.navigationEngine = navigationEngine
        self.climbEngine = climbEngine
    }

    func activate() {
        guard !isActive else { return }
        isActive = true

        startNavigationSnapshotConsumer()
    }

    func shutdown() {
        navigationSnapshotTask?.cancel()
        navigationSnapshotTask = nil
        isActive = false
    }

    // MARK: - Route Selection & Lifecycle

    func selectRoute(id: Route.ID) async {
        routeLoadGeneration += 1
        let generation = routeLoadGeneration

        do {
            let route = try await routeStore.loadRoute(id: id)

            guard generation == routeLoadGeneration else {
                return
            }

            activeRouteID = id

            await navigationEngine.send(.useRoute(route))
            await climbEngine.send(.loadRoute(route))
            await routeLibraryEngine.send(.setActiveRoute(id))
        } catch {
            guard generation == routeLoadGeneration else {
                return
            }

            activeRouteID = nil
            await navigationEngine.send(.reset)
            await climbEngine.send(.reset)
        }
    }

    func clearRoute() async {
        routeLoadGeneration += 1
        activeRouteID = nil

        await navigationEngine.send(.reset)
        await climbEngine.send(.reset)
        await routeLibraryEngine.send(.setActiveRoute(nil))
    }

    func canDeleteRoute(id: Route.ID) -> Bool {
        return id != activeRouteID
    }

    func deleteRoute(id: Route.ID) async throws {
        guard canDeleteRoute(id: id) else {
            throw RouteStoreError.activeRouteProtected(id)
        }
        await routeLibraryEngine.send(.deleteRoute(id))
    }

    // MARK: - Navigation to Climb Feeding

    private func startNavigationSnapshotConsumer() {
        let snapshots = navigationEngine.snapshots
        navigationSnapshotTask = Task { [weak self] in
            for await snapshot in snapshots {
                guard let self, !Task.isCancelled else { break }
                await self.climbEngine.send(.processNavigation(snapshot))
            }
        }
    }
}
