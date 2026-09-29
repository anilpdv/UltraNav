import XCTest
@testable import UltraNav

final class RouteStorageCodecTests: XCTestCase {
    private var codec: JSONRouteStorageCodec!

    override func setUp() {
        super.setUp()
        codec = JSONRouteStorageCodec()
    }

    func testEncodeAndDecodeRouteStorageRecordRoundtrip() throws {
        let route = Route(
            id: RouteID(sha256Hex: "testroundtrip"),
            metadata: RouteMetadata(
                name: "Roundtrip Route",
                description: "Testing json serialization",
                source: .importedGPX(originalFileName: "test.gpx"),
                importedAt: Date(timeIntervalSince1970: 1700000000),
                originalCreatedAt: Date(timeIntervalSince1970: 1699990000)
            ),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.33, longitude: -122.01), elevationMeters: 100, cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.34, longitude: -122.02), elevationMeters: 120, cumulativeDistanceMeters: 500)
            ],
            segments: [
                RouteSegment(segmentIndex: 0, startPointIndex: 0, endPointIndex: 1, distanceMeters: 500)
            ],
            waypoints: [
                RouteWaypoint(coordinate: Coordinate(latitude: 37.335, longitude: -122.015), name: "Midpoint", description: "Mid", symbol: "water", elevationMeters: 110)
            ],
            totalDistanceMeters: 500,
            totalAscentMeters: 20,
            totalDescentMeters: 0,
            minimumElevationMeters: 100,
            maximumElevationMeters: 120
        )

        let record = RouteStorageRecord(route: route)
        let data = try codec.encodeRecord(record)
        let decoded = try codec.decodeRecord(from: data)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.route.id, route.id)
        XCTAssertEqual(decoded.route.metadata.name, "Roundtrip Route")
        XCTAssertEqual(decoded.route.points.count, 2)
        XCTAssertEqual(decoded.route.segments.count, 1)
        XCTAssertEqual(decoded.route.waypoints.count, 1)
        XCTAssertEqual(decoded.summary.name, "Roundtrip Route")
        XCTAssertEqual(decoded.summary.pointCount, 2)
    }

    func testEncodeAndDecodeRouteStoreIndexRoundtrip() throws {
        let summary = RouteSummary(
            id: RouteID(sha256Hex: "sum1"),
            name: "Summary 1",
            totalDistanceMeters: 1500,
            pointCount: 10,
            createdAt: Date(timeIntervalSince1970: 1700000000)
        )
        let index = RouteStoreIndex(schemaVersion: 1, summaries: [summary], lastUpdated: Date(timeIntervalSince1970: 1700000100))

        let data = try codec.encodeIndex(index)
        let decoded = try codec.decodeIndex(from: data)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.summaries.count, 1)
        XCTAssertEqual(decoded.summaries[0].id, summary.id)
    }
}
