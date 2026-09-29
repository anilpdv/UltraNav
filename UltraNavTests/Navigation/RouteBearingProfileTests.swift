import XCTest
@testable import UltraNav

final class RouteBearingProfileTests: XCTestCase {
    func testStraightNorthRouteBearing() {
        // Point 1: 37.3300, -122.0100
        // Point 2: 37.3320, -122.0100 (North, bearing ~0°)
        // Point 3: 37.3340, -122.0100 (North, bearing ~0°)
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 222)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 37.3340, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 444)

        let route = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "Straight Route"),
            points: [p1, p2, p3],
            totalDistanceMeters: 444
        )

        let profile = RouteBearingProfile(route: route)

        XCTAssertEqual(profile.samples.count, 2)
        XCTAssertEqual(profile.totalDistanceMeters, 444.0, accuracy: 20.0)

        // Turn angle at midpoint should be near 0°
        let angle = profile.turnAngle(at: 222.0, windowMeters: 25.0)
        XCTAssertNotNil(angle)
        XCTAssertEqual(angle!, 0.0, accuracy: 2.0)
    }

    func testRightAngleTurnBearing() {
        // Leg 1: South to North (0°) ~222m
        // Leg 2: West to East (90°) ~222m
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 222)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0075), elevationMeters: 10, cumulativeDistanceMeters: 444)

        let route = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "Right Turn Route"),
            points: [p1, p2, p3],
            totalDistanceMeters: 444
        )

        let profile = RouteBearingProfile(route: route)

        let entry = profile.entryBearing(at: 222.0, windowMeters: 25.0)
        let exit = profile.exitBearing(at: 222.0, windowMeters: 25.0)
        let angle = profile.turnAngle(at: 222.0, windowMeters: 25.0)

        XCTAssertNotNil(entry)
        XCTAssertNotNil(exit)
        XCTAssertNotNil(angle)

        XCTAssertEqual(entry!, 0.0, accuracy: 5.0)
        XCTAssertEqual(exit!, 90.0, accuracy: 5.0)
        XCTAssertEqual(angle!, 90.0, accuracy: 5.0)
    }
}
