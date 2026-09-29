import XCTest
@testable import UltraNav

final class RouteIdentityTests: XCTestCase {
    private var identityCreator: SHA256RouteIdentityCreator!

    override func setUp() {
        super.setUp()
        identityCreator = SHA256RouteIdentityCreator()
    }

    func testIdenticalCoordinatesProduceIdenticalRouteIDs() {
        let pts1 = [
            Coordinate(latitude: 37.3349, longitude: -122.0090),
            Coordinate(latitude: 37.3359, longitude: -122.0090)
        ]
        let pts2 = [
            Coordinate(latitude: 37.3349, longitude: -122.0090),
            Coordinate(latitude: 37.3359, longitude: -122.0090)
        ]

        let id1 = identityCreator.makeRouteID(points: pts1, segmentBreaks: [1])
        let id2 = identityCreator.makeRouteID(points: pts2, segmentBreaks: [1])

        XCTAssertEqual(id1, id2)
        XCTAssertTrue(id1.rawValue.hasPrefix("route-v1:"))
    }

    func testDifferentCoordinatesProduceDistinctRouteIDs() {
        let pts1 = [
            Coordinate(latitude: 37.3349, longitude: -122.0090),
            Coordinate(latitude: 37.3359, longitude: -122.0090)
        ]
        let pts2 = [
            Coordinate(latitude: 37.3349, longitude: -122.0090),
            Coordinate(latitude: 37.3360, longitude: -122.0090)
        ]

        let id1 = identityCreator.makeRouteID(points: pts1, segmentBreaks: [1])
        let id2 = identityCreator.makeRouteID(points: pts2, segmentBreaks: [1])

        XCTAssertNotEqual(id1, id2)
    }
}
