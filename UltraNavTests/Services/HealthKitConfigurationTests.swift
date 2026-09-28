import Foundation
import HealthKit
import XCTest
@testable import UltraNav

final class HealthKitConfigurationTests: XCTestCase {
    func testOutdoorCyclingConfiguration() {
        let config = WorkoutConfiguration.outdoorCycling
        XCTAssertEqual(config.activity, .cycling)
        XCTAssertEqual(config.locationMode, .outdoor)

        let hkConfig = config.makeHealthKitConfiguration()
        XCTAssertEqual(hkConfig.activityType, .cycling)
        XCTAssertEqual(hkConfig.locationType, .outdoor)
    }
}
