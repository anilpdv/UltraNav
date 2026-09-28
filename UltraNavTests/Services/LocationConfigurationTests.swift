import XCTest
@testable import UltraNav

final class LocationConfigurationTests: XCTestCase {
    func testCyclingPreset() {
        let config = LocationConfiguration.cycling
        XCTAssertEqual(config.desiredAccuracyMeters, 10)
        XCTAssertEqual(config.distanceFilterMeters, 2)
        XCTAssertFalse(config.pausesAutomatically)
        XCTAssertTrue(config.allowsBackgroundUpdates)
    }
}
