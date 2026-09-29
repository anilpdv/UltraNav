import XCTest
@testable import UltraNav

@MainActor
final class RouteLibraryEngineTests: XCTestCase {
    private var fakeStore: FakeRouteStore!
    private var fakeImporter: FakeRouteImporter!
    private var engine: RouteLibraryEngine!

    override func setUp() async throws {
        try await super.setUp()
        let initialRoute = Route(
            id: RouteID(sha256Hex: "lib1"),
            metadata: RouteMetadata(name: "Initial Course"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.01, longitude: -122.0), cumulativeDistanceMeters: 100)
            ],
            totalDistanceMeters: 100
        )
        self.fakeStore = FakeRouteStore(routes: [initialRoute])
        self.fakeImporter = FakeRouteImporter()
        self.engine = RouteLibraryEngine(store: fakeStore, importer: fakeImporter)
    }

    func testLoadCommandUpdatesSnapshotToReadyWithSummaries() async {
        await engine.send(.load)

        XCTAssertEqual(engine.currentSnapshot.state, .ready)
        XCTAssertEqual(engine.currentSnapshot.routes.count, 1)
        XCTAssertEqual(engine.currentSnapshot.routes[0].name, "Initial Course")
    }

    func testImportSourceCommandAddsRouteAndUpdatesSnapshot() async {
        await engine.send(.load)
        await engine.send(.importSource(.data(Data(), originalFileName: "test.gpx")))

        XCTAssertEqual(engine.currentSnapshot.state, .ready)
        XCTAssertEqual(fakeImporter.importCallCount, 1)
        XCTAssertEqual(engine.currentSnapshot.selectedRouteID, RouteID(sha256Hex: "fakeimport"))
    }

    func testDeleteActiveRouteIsProtected() async {
        let activeID = RouteID(sha256Hex: "lib1")
        await engine.send(.load)
        await engine.send(.setActiveRoute(activeID))

        await engine.send(.deleteRoute(activeID))

        guard case .failed(let failure) = engine.currentSnapshot.state else {
            XCTFail("Expected failed state")
            return
        }
        XCTAssertEqual(failure, .activeRouteProtected(activeID))
    }

    func testDeleteInactiveRouteSucceeds() async {
        await engine.send(.load)
        await engine.send(.deleteRoute(RouteID(sha256Hex: "lib1")))

        XCTAssertEqual(engine.currentSnapshot.state, .ready)
        XCTAssertTrue(engine.currentSnapshot.routes.isEmpty)
    }
}
