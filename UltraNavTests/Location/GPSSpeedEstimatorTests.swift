import XCTest
@testable import UltraNav

final class GPSSpeedEstimatorTests: XCTestCase {
    private var estimator: GPSSpeedEstimator!
    private var config: GPSProcessingConfiguration!

    override func setUp() {
        super.setUp()
        estimator = GPSSpeedEstimator()
        config = GPSProcessingConfiguration(maximumPlausibleSpeedMetersPerSecond: 35.0)
    }

    func testPlatformReportedSpeedPreferred() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            speedMetersPerSecond: 8.5,
            timestamp: Date()
        )

        let result = estimator.estimate(
            current: sample,
            previous: nil,
            distanceMeters: nil,
            timeDeltaSeconds: nil,
            configuration: config
        )

        XCTAssertEqual(result.source, .platformReported)
        XCTAssertEqual(result.metersPerSecond, 8.5)
    }

    func testPositionDerivedSpeedFallback() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            speedMetersPerSecond: nil, // Platform speed unavailable
            timestamp: Date()
        )

        let result = estimator.estimate(
            current: sample,
            previous: nil,
            distanceMeters: 20.0,
            timeDeltaSeconds: 2.0,
            configuration: config
        )

        XCTAssertEqual(result.source, .positionDerived)
        XCTAssertEqual(result.metersPerSecond, 10.0)
    }

    func testUnavailableSpeedWhenNoReportOrDistance() {
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.33, longitude: -122.01),
            speedMetersPerSecond: nil,
            timestamp: Date()
        )

        let result = estimator.estimate(
            current: sample,
            previous: nil,
            distanceMeters: nil,
            timeDeltaSeconds: nil,
            configuration: config
        )

        XCTAssertEqual(result.source, .unavailable)
        XCTAssertNil(result.metersPerSecond)
    }
}
