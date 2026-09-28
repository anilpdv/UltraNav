import XCTest
@testable import UltraNav

final class SensorModelTests: XCTestCase {
    func testSensorSampleStoresTypedValues() {
        let date = Date(timeIntervalSince1970: 1704067200)
        let sample = SensorSample.heartRate(beatsPerMinute: 155, timestamp: date)

        if case let .heartRate(bpm, timestamp) = sample {
            XCTAssertEqual(bpm, 155)
            XCTAssertEqual(timestamp, date)
        } else {
            XCTFail("Expected .heartRate sample")
        }
    }
}
