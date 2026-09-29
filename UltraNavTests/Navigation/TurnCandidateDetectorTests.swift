import XCTest
@testable import UltraNav

final class TurnCandidateDetectorTests: XCTestCase {
    func testDetectsSingleRightTurn() {
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
        let detector = TurnCandidateDetector()
        let candidates = detector.detectCandidates(profile: profile)

        XCTAssertEqual(candidates.count, 1)
        if let candidate = candidates.first {
            XCTAssertEqual(candidate.maneuver, .right)
            XCTAssertEqual(candidate.turnAngleDegrees, 90.0, accuracy: 10.0)
            XCTAssertEqual(candidate.distanceAlongRouteMeters, 222.0, accuracy: 25.0)
        }
    }

    func testStraightRouteYieldsZeroCandidates() {
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
        let detector = TurnCandidateDetector()
        let candidates = detector.detectCandidates(profile: profile)

        XCTAssertEqual(candidates.count, 0)
    }
}
