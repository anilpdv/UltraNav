import XCTest
@testable import UltraNav

final class RouteMatcherTests: XCTestCase {
    private var matcher: RouteMatcher!
    private var sampleRoute: Route!

    override func setUp() {
        super.setUp()
        matcher = RouteMatcher()

        // 3-point route going North: (0m) -> (222m) -> (444m)
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 222)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 37.3340, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 444)

        sampleRoute = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "Sample Route"),
            points: [p1, p2, p3],
            totalDistanceMeters: 444
        )
    }

    func testStraightRouteProjectionProgression() throws {
        let loc1 = LocationSample(
            coordinate: Coordinate(latitude: 37.3310, longitude: -122.0100),
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 10.0,
            courseDegrees: 0.0,
            timestamp: Date()
        )

        let match1 = try matcher.match(location: loc1, route: sampleRoute, previousMatch: nil)
        XCTAssertNotNil(match1)
        XCTAssertEqual(match1?.segmentIndex, 0)
        XCTAssertEqual(match1?.confidence, .high)
        XCTAssertLessThan(match1?.crossTrackDistanceMeters ?? 100, 2.0)
        XCTAssertEqual(match1?.distanceAlongRouteMeters ?? 0, 111.0, accuracy: 15.0)

        // Advance further along segment 1
        let loc2 = LocationSample(
            coordinate: Coordinate(latitude: 37.3330, longitude: -122.0100),
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 10.0,
            courseDegrees: 0.0,
            timestamp: Date().addingTimeInterval(10)
        )

        let match2 = try matcher.match(location: loc2, route: sampleRoute, previousMatch: match1)
        XCTAssertNotNil(match2)
        XCTAssertEqual(match2?.segmentIndex, 1)
        XCTAssertGreaterThan(match2?.distanceAlongRouteMeters ?? 0, match1?.distanceAlongRouteMeters ?? 0)
    }

    func testHeadingAlignmentPrioritizesCorrectDirection() throws {
        // Two parallel opposing segments:
        // Segment 0: South to North (bearing 0°) from dist 0 to 222m
        // Segment 1: North to South (bearing 180°) from dist 222m to 444m
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.3320, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 222)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 444)

        let uTurnRoute = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "UTurn Route"),
            points: [p1, p2, p3],
            totalDistanceMeters: 444
        )

        // Location in the middle facing South (heading 180°) moving at 8 m/s
        let locSouth = LocationSample(
            coordinate: Coordinate(latitude: 37.3310, longitude: -122.0100),
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 8.0,
            courseDegrees: 180.0,
            timestamp: Date()
        )

        let match = try matcher.match(location: locSouth, route: uTurnRoute, previousMatch: nil)
        XCTAssertNotNil(match)
        // Should match southbound segment 1, not northbound segment 0!
        XCTAssertEqual(match?.segmentIndex, 1)
        XCTAssertGreaterThan(match?.distanceAlongRouteMeters ?? 0, 222.0)
    }

    func testContinuityPreventsPrematureLoopJumping() throws {
        // Loop route where path crosses itself at start (dist 0 and dist 500)
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 37.3310, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 111)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 37.3310, longitude: -122.0080), elevationMeters: 10, cumulativeDistanceMeters: 250)
        let p4 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0080), elevationMeters: 10, cumulativeDistanceMeters: 390)
        let p5 = RoutePoint(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), elevationMeters: 10, cumulativeDistanceMeters: 500)

        let loopRoute = Route(
            id: UUID(),
            metadata: RouteMetadata(name: "Loop Route"),
            points: [p1, p2, p3, p4, p5],
            totalDistanceMeters: 500
        )

        let initialMatch = RouteMatch(
            matchedCoordinate: p1.coordinate,
            segmentIndex: 0,
            distanceAlongRouteMeters: 5.0,
            crossTrackDistanceMeters: 1.0,
            confidence: .high
        )

        // Next point is 20m into the first leg
        let loc = LocationSample(
            coordinate: Coordinate(latitude: 37.3302, longitude: -122.0100),
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 5.0,
            courseDegrees: 0.0,
            timestamp: Date()
        )

        let match = try matcher.match(location: loc, route: loopRoute, previousMatch: initialMatch)
        XCTAssertNotNil(match)
        // Continuity penalty prevents snapping to the final segment (dist 500m)
        XCTAssertEqual(match?.segmentIndex, 0)
        XCTAssertLessThan(match?.distanceAlongRouteMeters ?? 500, 100.0)
    }

    func testOffRouteDistantLocationReturnsLowConfidence() throws {
        // Location 200m away to the east
        let locOffRoute = LocationSample(
            coordinate: Coordinate(latitude: 37.3310, longitude: -122.0070),
            horizontalAccuracyMeters: 5.0,
            speedMetersPerSecond: 5.0,
            courseDegrees: 0.0,
            timestamp: Date()
        )

        let match = try matcher.match(location: locOffRoute, route: sampleRoute, previousMatch: nil)
        XCTAssertNotNil(match)
        XCTAssertEqual(match?.confidence, .low)
        XCTAssertGreaterThan(match?.crossTrackDistanceMeters ?? 0, 60.0)
    }
}
