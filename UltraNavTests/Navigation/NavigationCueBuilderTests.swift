import XCTest
@testable import UltraNav

final class NavigationCueBuilderTests: XCTestCase {
    func testDeterministicCueSynthesis() throws {
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 222)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0075), elevationMeters: 10, cumulativeDistanceMeters: 444)

        let routeID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let route = Route(
            id: routeID,
            metadata: RouteMetadata(name: "Right Turn Route"),
            points: [p1, p2, p3],
            totalDistanceMeters: 444
        )

        let builder = NavigationCueBuilder()
        let cues1 = try builder.cues(for: route)
        let cues2 = try builder.cues(for: route)

        XCTAssertEqual(cues1.count, 2) // 1 turn + 1 arrival
        XCTAssertEqual(cues1, cues2) // Deterministic output

        let turnCue = cues1[0]
        XCTAssertEqual(turnCue.maneuver, .right)
        XCTAssertEqual(turnCue.instruction, "Turn right")
        XCTAssertEqual(turnCue.routeDistanceMeters, 222.0, accuracy: 25.0)

        let arrivalCue = cues1[1]
        XCTAssertEqual(arrivalCue.maneuver, .arrive)
        XCTAssertEqual(arrivalCue.instruction, "Arrive at destination")
        XCTAssertEqual(arrivalCue.routeDistanceMeters, 444.0, accuracy: 20.0)
    }
}
