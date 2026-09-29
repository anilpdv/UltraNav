import XCTest
@testable import UltraNav

final class GPSDistanceAccumulatorTests: XCTestCase {
    private var accumulator: GPSDistanceAccumulator!

    override func setUp() {
        super.setUp()
        accumulator = GPSDistanceAccumulator()
    }

    func testInitialSampleAddsZeroDistance() {
        let s = LocationSample(coordinate: Coordinate(latitude: 37.33, longitude: -122.01), timestamp: Date())
        let r = accumulator.evaluate(previous: nil, current: s, movementState: .moving, distanceMeters: nil, bridgeAllowed: true)

        XCTAssertEqual(r.incrementMeters, 0.0)
        XCTAssertEqual(r.totalMeters, 0.0)
        XCTAssertTrue(r.shouldAdvanceAnchor)
    }

    func testMovingSampleAccumulatesDistance() {
        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.33, longitude: -122.01), timestamp: Date())
        let s2 = LocationSample(coordinate: Coordinate(latitude: 37.331, longitude: -122.01), timestamp: Date())

        _ = accumulator.evaluate(previous: nil, current: s1, movementState: .moving, distanceMeters: nil, bridgeAllowed: true)
        let r = accumulator.evaluate(previous: s1, current: s2, movementState: .moving, distanceMeters: 111.0, bridgeAllowed: true)

        XCTAssertEqual(r.incrementMeters, 111.0)
        XCTAssertEqual(r.totalMeters, 111.0)
        XCTAssertEqual(accumulator.totalDistanceMeters, 111.0)
    }

    func testStationaryDriftAddsZeroDistance() {
        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.33, longitude: -122.01), timestamp: Date())
        let s2 = LocationSample(coordinate: Coordinate(latitude: 37.33002, longitude: -122.01), timestamp: Date())

        _ = accumulator.evaluate(previous: nil, current: s1, movementState: .moving, distanceMeters: nil, bridgeAllowed: true)
        let r = accumulator.evaluate(previous: s1, current: s2, movementState: .stationary, distanceMeters: 2.2, bridgeAllowed: true)

        XCTAssertEqual(r.incrementMeters, 0.0)
        XCTAssertEqual(r.totalMeters, 0.0)
        XCTAssertTrue(r.shouldAdvanceAnchor)
    }

    func testBridgeNotAllowedAddsZeroDistance() {
        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.33, longitude: -122.01), timestamp: Date())
        let s2 = LocationSample(coordinate: Coordinate(latitude: 37.34, longitude: -122.01), timestamp: Date())

        _ = accumulator.evaluate(previous: nil, current: s1, movementState: .moving, distanceMeters: nil, bridgeAllowed: true)
        let r = accumulator.evaluate(previous: s1, current: s2, movementState: .moving, distanceMeters: 1110.0, bridgeAllowed: false) // Long gap / outage

        XCTAssertEqual(r.incrementMeters, 0.0)
        XCTAssertEqual(r.totalMeters, 0.0)
        XCTAssertTrue(r.shouldAdvanceAnchor)
    }
}
