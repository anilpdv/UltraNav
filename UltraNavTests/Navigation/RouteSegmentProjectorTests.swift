import XCTest
@testable import UltraNav

final class RouteSegmentProjectorTests: XCTestCase {
    private var projector: RouteSegmentProjector!

    override func setUp() {
        super.setUp()
        projector = RouteSegmentProjector()
    }

    func testProjectionOnSegmentMidpoint() {
        let p1 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 0
        )
        // ~222 meters north
        let p2 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 222
        )
        let edge = RouteGeometryEdge(index: 0, startPoint: p1, endPoint: p2)

        // Point exactly in the middle
        let target = Coordinate(latitude: 37.3310, longitude: -122.0100)
        let result = projector.project(coordinate: target, onto: edge)

        XCTAssertEqual(result.fraction, 0.5, accuracy: 0.05)
        XCTAssertLessThan(result.crossTrackDistanceMeters, 1.0)
        XCTAssertEqual(result.distanceAlongRouteMeters, 111.0, accuracy: 15.0)
    }

    func testPerpendicularOffset() {
        let p1 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 0
        )
        let p2 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 222
        )
        let edge = RouteGeometryEdge(index: 0, startPoint: p1, endPoint: p2)

        let target = Coordinate(latitude: 37.3310, longitude: -122.0098)
        let result = projector.project(coordinate: target, onto: edge)

        XCTAssertEqual(result.fraction, 0.5, accuracy: 0.05)
        XCTAssertEqual(result.crossTrackDistanceMeters, 17.6, accuracy: 3.0)
    }

    func testClampingBeforeStartPoint() {
        let p1 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 0
        )
        let p2 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 222
        )
        let edge = RouteGeometryEdge(index: 0, startPoint: p1, endPoint: p2)

        let target = Coordinate(latitude: 37.3290, longitude: -122.0100)
        let result = projector.project(coordinate: target, onto: edge)

        XCTAssertEqual(result.fraction, 0.0)
        XCTAssertEqual(result.distanceAlongRouteMeters, 0.0)
    }

    func testClampingAfterEndPoint() {
        let p1 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 0
        )
        let p2 = RoutePoint(
            coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100),
            elevationMeters: 10,
            cumulativeDistanceMeters: 222
        )
        let edge = RouteGeometryEdge(index: 0, startPoint: p1, endPoint: p2)

        let target = Coordinate(latitude: 37.3330, longitude: -122.0100)
        let result = projector.project(coordinate: target, onto: edge)

        XCTAssertEqual(result.fraction, 1.0)
        XCTAssertEqual(result.distanceAlongRouteMeters, 222.0)
    }
}
