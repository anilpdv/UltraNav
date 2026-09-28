import XCTest
@testable import UltraNav

final class LocationSampleTests: XCTestCase {
    func testLocationSampleStoresExplicitUnits() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let sample = LocationSample(
            coordinate: Coordinate(latitude: 37.3349, longitude: -122.0090),
            altitudeMeters: 150.5,
            horizontalAccuracyMeters: 5.0,
            verticalAccuracyMeters: 3.0,
            speedMetersPerSecond: 8.33,
            courseDegrees: 180.0,
            timestamp: date
        )

        XCTAssertEqual(sample.coordinate.latitude, 37.3349)
        XCTAssertEqual(sample.coordinate.longitude, -122.0090)
        XCTAssertEqual(sample.altitudeMeters, 150.5)
        XCTAssertEqual(sample.horizontalAccuracyMeters, 5.0)
        XCTAssertEqual(sample.verticalAccuracyMeters, 3.0)
        XCTAssertEqual(sample.speedMetersPerSecond, 8.33)
        XCTAssertEqual(sample.courseDegrees, 180.0)
        XCTAssertEqual(sample.timestamp, date)
    }
}
