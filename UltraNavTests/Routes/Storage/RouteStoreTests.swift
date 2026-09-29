import XCTest
@testable import UltraNav

final class RouteStoreTests: XCTestCase {
    private var tempDir: URL!
    private var store: RouteStore!

    override func setUp() async throws {
        try await super.setUp()
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.tempDir = dir
        self.store = RouteStore(storageDirectory: dir)
    }

    override func tearDown() async throws {
        if let dir = tempDir {
            try? FileManager.default.removeItem(at: dir)
        }
        try await super.tearDown()
    }

    func testSaveAndLoadRoute() async throws {
        let route = Route(
            id: RouteID(sha256Hex: "storetest1"),
            metadata: RouteMetadata(name: "Test Course Alpha"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.1, longitude: -122.0), cumulativeDistanceMeters: 1000)
            ],
            totalDistanceMeters: 1000
        )

        let outcome = try await store.saveRoute(route, behavior: .failIfExists)
        XCTAssertEqual(outcome, .savedNew)

        let exists = await store.routeExists(id: route.id)
        XCTAssertTrue(exists)

        let loaded = try await store.loadRoute(id: route.id)
        XCTAssertEqual(loaded.id, route.id)
        XCTAssertEqual(loaded.metadata.name, "Test Course Alpha")

        let summaries = try await store.listRoutes()
        XCTAssertEqual(summaries.count, 1)
        XCTAssertEqual(summaries[0].id, route.id)
    }

    func testSaveDuplicateWithFailIfExistsThrows() async throws {
        let route = Route(
            id: RouteID(sha256Hex: "storetest2"),
            metadata: RouteMetadata(name: "Duplicate Test"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.1, longitude: -122.0), cumulativeDistanceMeters: 1000)
            ],
            totalDistanceMeters: 1000
        )

        _ = try await store.saveRoute(route, behavior: .failIfExists)

        do {
            _ = try await store.saveRoute(route, behavior: .failIfExists)
            XCTFail("Expected duplicateRoute error")
        } catch let err as RouteStoreError {
            XCTAssertEqual(err, .duplicateRoute(route.id))
        }
    }

    func testDeleteActiveRouteThrowsProtectedError() async throws {
        let route = Route(
            id: RouteID(sha256Hex: "storetest3"),
            metadata: RouteMetadata(name: "Active Test"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.1, longitude: -122.0), cumulativeDistanceMeters: 1000)
            ],
            totalDistanceMeters: 1000
        )

        _ = try await store.saveRoute(route)

        do {
            try await store.deleteRoute(id: route.id, activeRouteID: route.id)
            XCTFail("Expected activeRouteProtected error")
        } catch let err as RouteStoreError {
            XCTAssertEqual(err, .activeRouteProtected(route.id))
        }

        // Verify route still exists
        let exists = await store.routeExists(id: route.id)
        XCTAssertTrue(exists)
    }

    func testDeleteInactiveRouteSucceeds() async throws {
        let route = Route(
            id: RouteID(sha256Hex: "storetest4"),
            metadata: RouteMetadata(name: "Delete Test"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.1, longitude: -122.0), cumulativeDistanceMeters: 1000)
            ],
            totalDistanceMeters: 1000
        )

        _ = try await store.saveRoute(route)
        try await store.deleteRoute(id: route.id, activeRouteID: RouteID(sha256Hex: "other"))

        let exists = await store.routeExists(id: route.id)
        XCTAssertFalse(exists)

        let summaries = try await store.listRoutes()
        XCTAssertTrue(summaries.isEmpty)
    }
}
