import Foundation
import XCTest
@testable import UltraNav

final class SHA256RouteIdentityCreatorTests: XCTestCase {
    private var creator: SHA256RouteIdentityCreator!

    override func setUp() {
        super.setUp()
        creator = SHA256RouteIdentityCreator()
    }

    override func tearDown() {
        creator = nil
        super.tearDown()
    }

    func testDeterministicRouteIDGeneration() {
        let coords = [
            Coordinate(latitude: 37.7749, longitude: -122.4194),
            Coordinate(latitude: 37.7750, longitude: -122.4195)
        ]
        let breaks = [1]

        let id1 = creator.makeRouteID(points: coords, segmentBreaks: breaks, version: .version2)
        let id2 = creator.makeRouteID(points: coords, segmentBreaks: breaks, version: .version2)

        XCTAssertEqual(id1, id2)
        XCTAssertFalse(id1.rawValue.isEmpty)
    }

    func testFingerprintsChangeWhenElevationChanges() {
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), elevationMeters: 100.0, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.1, longitude: -122.1), elevationMeters: 110.0, cumulativeDistanceMeters: 1000)
        let seg = RouteSegment(startPointIndex: 0, endPointIndex: 1, startDistanceMeters: 0, endDistanceMeters: 1000)

        let fp1 = creator.makeFingerprints(points: [p1, p2], segments: [seg], waypoints: [], version: .version2)

        let p2Higher = RoutePoint(coordinate: Coordinate(latitude: 37.1, longitude: -122.1), elevationMeters: 200.0, cumulativeDistanceMeters: 1000)
        let fp2 = creator.makeFingerprints(points: [p1, p2Higher], segments: [seg], waypoints: [], version: .version2)

        // Geometry ID should be identical (coordinates didn't change)
        XCTAssertEqual(fp1.geometryID, fp2.geometryID)

        // Content fingerprint MUST differ because elevation changed
        XCTAssertNotEqual(fp1.contentFingerprint, fp2.contentFingerprint)
    }
}
