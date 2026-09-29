import XCTest
@testable import UltraNav

@MainActor
final class RouteNavigationIntegrationTests: XCTestCase {
    func testImportRouteStoreAndLoadIntoNavigationEngine() async throws {
        // 1. Setup temp directory and services
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = RouteStore(storageDirectory: tempDir)
        let importer = RouteImporter()
        let navEngine = NavigationEngine(routeStore: store)

        // 2. Import a GPX track
        let gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Integration Test">
          <metadata><name>End to End Course</name></metadata>
          <trk>
            <trkseg>
              <trkpt lat="37.3349" lon="-122.0090"><ele>100</ele></trkpt>
              <trkpt lat="37.3359" lon="-122.0090"><ele>110</ele></trkpt>
              <trkpt lat="37.3369" lon="-122.0090"><ele>120</ele></trkpt>
            </trkseg>
          </trk>
        </gpx>
        """.data(using: .utf8)!

        let importResult = try await importer.importRoute(from: .data(gpx, originalFileName: "e2e.gpx"))
        _ = try await store.saveRoute(importResult.route)

        // 3. Command NavigationEngine to load the route by ID
        await navEngine.send(.loadRoute(importResult.route.id))

        // 4. Verify NavigationEngine snapshot has the loaded route
        XCTAssertEqual(navEngine.currentSnapshot.routeID, importResult.route.id)
        XCTAssertEqual(navEngine.routeState.route?.metadata.name, "End to End Course")
        XCTAssertEqual(navEngine.routeState.route?.points.count, 3)
    }
}
