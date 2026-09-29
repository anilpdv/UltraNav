import Foundation
@testable import UltraNav

@MainActor
final class RoutePipelineHarness {
    let store: FakeRouteStore
    let importer: FakeRouteImporter
    let engine: RouteLibraryEngine
    let snapshots: SnapshotRecorder<RouteLibrarySnapshot>
    private var snapshotTask: Task<Void, Never>?

    init(
        store: FakeRouteStore = FakeRouteStore(),
        importer: FakeRouteImporter = FakeRouteImporter()
    ) {
        self.store = store
        self.importer = importer
        self.engine = RouteLibraryEngine(store: store, importer: importer)
        self.snapshots = SnapshotRecorder()
    }

    func start() {
        snapshotTask = recordSnapshots(from: engine.snapshots, into: snapshots)
    }

    func shutdown() {
        snapshotTask?.cancel()
        snapshotTask = nil
    }

    func importDefaultRoute() async throws -> Route {
        let route = RouteFixture.straightRoute()
        importer.resultToReturn = RouteImportResult(route: route, warnings: [])
        await engine.send(.importSource(.data(Data(), originalFileName: "straight.gpx"), policy: .default))
        return route
    }

    func loadRoute(id: Route.ID) async throws -> Route {
        try await store.loadRoute(id: id)
    }
}
