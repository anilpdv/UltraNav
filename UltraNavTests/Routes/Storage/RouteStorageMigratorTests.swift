import Foundation
import XCTest
@testable import UltraNav

final class RouteStorageMigratorTests: XCTestCase {
    private var migrator: RouteStorageMigrator!

    override func setUp() {
        super.setUp()
        migrator = RouteStorageMigrator()
    }

    override func tearDown() {
        migrator = nil
        super.tearDown()
    }

    func testMigrateV1SchemaRecordToV2() throws {
        let route = RouteFixture.straightRoute()
        let summary = RouteSummary(from: route)
        let v1 = RouteStorageRecordV1(schemaVersion: 1, route: route, summary: summary)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let v1Data = try encoder.encode(v1)

        let migrated = try migrator.migrate(data: v1Data)

        XCTAssertEqual(migrated.schemaVersion, 2)
        XCTAssertEqual(migrated.normalizationVersion, .version2)
        XCTAssertEqual(migrated.route.id, route.id)
        XCTAssertNotNil(migrated.fingerprints)
    }

    func testDecodeV2SchemaDirectly() throws {
        let route = RouteFixture.straightRoute()
        let summary = RouteSummary(from: route)
        let fingerprints = RouteFingerprints(geometryID: route.id.rawValue, contentFingerprint: "test-hash")
        let v2 = RouteStorageRecordV2(
            schemaVersion: 2,
            normalizationVersion: .version2,
            route: route,
            summary: summary,
            fingerprints: fingerprints
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let v2Data = try encoder.encode(v2)

        let decoded = try migrator.migrate(data: v2Data)

        XCTAssertEqual(decoded.schemaVersion, 2)
        XCTAssertEqual(decoded.fingerprints?.contentFingerprint, "test-hash")
    }
}
