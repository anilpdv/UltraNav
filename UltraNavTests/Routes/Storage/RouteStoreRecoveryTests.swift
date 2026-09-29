import XCTest
@testable import UltraNav

final class RouteStoreRecoveryTests: XCTestCase {
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

    func testCorruptedIndexFileTriggersAutomaticRebuildFromRecords() async throws {
        let route1 = Route(
            id: RouteID(sha256Hex: "rec1"),
            metadata: RouteMetadata(name: "Route 1"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.1, longitude: -122.0), cumulativeDistanceMeters: 1000)
            ],
            totalDistanceMeters: 1000
        )
        let route2 = Route(
            id: RouteID(sha256Hex: "rec2"),
            metadata: RouteMetadata(name: "Route 2"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.2, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.3, longitude: -122.0), cumulativeDistanceMeters: 1000)
            ],
            totalDistanceMeters: 1000
        )

        _ = try await store.saveRoute(route1)
        _ = try await store.saveRoute(route2)

        // Corrupt index-v1.json
        let indexURL = tempDir.appendingPathComponent("index-v1.json")
        try "CORRUPTED GARBAGE JSON CONTENT".write(to: indexURL, atomically: true, encoding: .utf8)

        // Create a new store instance pointing to the same folder to bypass memory cache
        let recoveredStore = RouteStore(storageDirectory: tempDir)
        let summaries = try await recoveredStore.listRoutes()

        XCTAssertEqual(summaries.count, 2)
        XCTAssertTrue(summaries.contains { $0.id == route1.id })
        XCTAssertTrue(summaries.contains { $0.id == route2.id })
    }
}
