import XCTest
@testable import UltraNav

final class GPSAccuracyValidatorTests: XCTestCase {
    private var validator: GPSAccuracyValidator!
    private var config: GPSProcessingConfiguration!

    override func setUp() {
        super.setUp()
        validator = GPSAccuracyValidator()
        config = GPSProcessingConfiguration(
            maximumHorizontalAccuracyMeters: 25.0,
            preferredHorizontalAccuracyMeters: 10.0
        )
    }

    func testExcellentAccuracyAccepted() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            horizontalAccuracyMeters: 3.5,
            timestamp: Date()
        )

        let result = validator.validate(sample, configuration: config)
        XCTAssertEqual(result, .accepted(.excellent))
    }

    func testGoodAccuracyAccepted() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            horizontalAccuracyMeters: 7.2,
            timestamp: Date()
        )

        let result = validator.validate(sample, configuration: config)
        XCTAssertEqual(result, .accepted(.good))
    }

    func testUsableAccuracyAccepted() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            horizontalAccuracyMeters: 18.0,
            timestamp: Date()
        )

        let result = validator.validate(sample, configuration: config)
        XCTAssertEqual(result, .accepted(.usable))
    }

    func testTooPoorAccuracyRejected() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            horizontalAccuracyMeters: 45.0, // > 25m
            timestamp: Date()
        )

        let result = validator.validate(sample, configuration: config)
        if case .tooPoor(let actual, let maxAcc) = result {
            XCTAssertEqual(actual, 45.0)
            XCTAssertEqual(maxAcc, 25.0)
        } else {
            XCTFail("Expected tooPoor result, got: \(result)")
        }
    }

    func testNegativeAccuracyRejected() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            horizontalAccuracyMeters: -1.0,
            timestamp: Date()
        )

        let result = validator.validate(sample, configuration: config)
        XCTAssertEqual(result, .invalid)
    }
}
