import XCTest
@testable import UltraNav

final class RouteModelTests: XCTestCase {
    func testRouteUsesInjectedIdentity() {
        let routeID = RouteID(sha256Hex: "000000000000000000000001")

        let route = Route(
            id: routeID,
            metadata: RouteMetadata(
                name: "Test Route",
                description: "Test description",
                source: .importedGPX(originalFileName: "test.gpx"),
                importedAt: Date(),
                originalCreatedAt: nil
            ),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.33, longitude: -122.01), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.34, longitude: -122.02), cumulativeDistanceMeters: 100)
            ],
            totalDistanceMeters: 100
        )

        XCTAssertEqual(route.id, routeID)
        XCTAssertEqual(route.metadata.name, "Test Route")
        XCTAssertEqual(route.points.count, 2)
        XCTAssertEqual(route.segments.count, 1)
        XCTAssertEqual(route.totalDistanceMeters, 100)
    }
}
