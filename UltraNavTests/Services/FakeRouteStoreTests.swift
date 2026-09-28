import XCTest
@testable import UltraNav

final class FakeRouteStoreTests: XCTestCase {
    func testSaveAndLoadRoute() async throws {
        let store = FakeRouteStore()
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let route = Route(
            id: id,
            metadata: RouteMetadata(
                name: "Test Route",
                sourceFileName: "test.gpx",
                createdAt: nil
            ),
            points: [
                RoutePoint(
                    coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194),
                    elevationMeters: 10,
                    timestamp: nil,
                    cumulativeDistanceMeters: 0
                )
            ],
            totalDistanceMeters: 0
        )

        let initialExists = await store.routeExists(id: id)
        XCTAssertFalse(initialExists)

        try await store.saveRoute(route)

        let existsAfterSave = await store.routeExists(id: id)
        XCTAssertTrue(existsAfterSave)

        let loaded = try await store.loadRoute(id: id)
        XCTAssertEqual(loaded, route)

        let summaries = try await store.listRoutes()
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries.first?.id, id)
        XCTAssertEqual(summaries.first?.name, "Test Route")
        XCTAssertEqual(summaries.first?.pointCount, 1)

        try await store.deleteRoute(id: id)
        let existsAfterDelete = await store.routeExists(id: id)
        XCTAssertFalse(existsAfterDelete)
    }

    func testLoadMissingRouteThrows() async {
        let store = FakeRouteStore()
        let id = UUID()

        do {
            _ = try await store.loadRoute(id: id)
            XCTFail("Expected loadRoute to throw")
        } catch {
            XCTAssertEqual(error as? RouteStoreError, .routeNotFound)
        }

        do {
            try await store.deleteRoute(id: id)
            XCTFail("Expected deleteRoute to throw")
        } catch {
            XCTAssertEqual(error as? RouteStoreError, .routeNotFound)
        }
    }
}
