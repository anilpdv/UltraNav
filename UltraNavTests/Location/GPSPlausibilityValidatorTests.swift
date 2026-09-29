import XCTest
@testable import UltraNav

final class GPSPlausibilityValidatorTests: XCTestCase {
    private var validator: GPSPlausibilityValidator!
    private var config: GPSProcessingConfiguration!

    override func setUp() {
        super.setUp()
        validator = GPSPlausibilityValidator(distanceCalculator: CoreLocationDistanceCalculator())
        config = GPSProcessingConfiguration(
            maximumPlausibleSpeedMetersPerSecond: 35.0,
            accuracyOverlapMultiplier: 1.0
        )
    }

    func testPlausibleMovementDetected() {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        let t1 = Date(timeIntervalSince1970: 1700000002) // 2s

        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), horizontalAccuracyMeters: 5, timestamp: t0)
        let s2 = LocationSample(coordinate: Coordinate(latitude: 37.3302, longitude: -122.0100), horizontalAccuracyMeters: 5, timestamp: t1) // ~22m in 2s = ~11 m/s

        let result = validator.validate(current: s2, previous: s1, configuration: config)

        if case .plausible(let dist, let speed, let overlap) = result {
            XCTAssertGreaterThan(dist, 20.0)
            XCTAssertLessThan(dist, 25.0)
            XCTAssertGreaterThan(speed, 10.0)
            XCTAssertLessThan(speed, 13.0)
            XCTAssertFalse(overlap) // 22m > 10m overlap threshold
        } else {
            XCTFail("Expected plausible result, got: \(result)")
        }
    }

    func testAccuracyOverlapDriftDetected() {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        let t1 = Date(timeIntervalSince1970: 1700000001)

        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.330000, longitude: -122.010000), horizontalAccuracyMeters: 8, timestamp: t0)
        let s2 = LocationSample(coordinate: Coordinate(latitude: 37.330030, longitude: -122.010000), horizontalAccuracyMeters: 8, timestamp: t1) // ~3.3m < 16m accuracy sum

        let result = validator.validate(current: s2, previous: s1, configuration: config)

        if case .plausible(_, _, let overlap) = result {
            XCTAssertTrue(overlap)
        } else {
            XCTFail("Expected plausible with overlap, got: \(result)")
        }
    }

    func testImplausibleTeleportRejected() {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        let t1 = Date(timeIntervalSince1970: 1700000001) // 1s later

        let s1 = LocationSample(coordinate: Coordinate(latitude: 37.3300, longitude: -122.0100), horizontalAccuracyMeters: 5, timestamp: t0)
        let s2 = LocationSample(coordinate: Coordinate(latitude: 37.3400, longitude: -122.0100), horizontalAccuracyMeters: 5, timestamp: t1) // ~1.1km in 1s = 1100 m/s > 35 m/s

        let result = validator.validate(current: s2, previous: s1, configuration: config)

        if case .implausibleSpeed(let speed) = result {
            XCTAssertGreaterThan(speed, 1000.0)
        } else {
            XCTFail("Expected implausibleSpeed result, got: \(result)")
        }
    }
}
