import XCTest
@testable import UltraNav

final class HeartRateMeasurementParserTests: XCTestCase {
    private var parser: HeartRateMeasurementParser!

    override func setUp() {
        super.setUp()
        parser = HeartRateMeasurementParser()
    }

    func test_parse8BitHeartRate() throws {
        // Flags: 0x00 (8-bit HR), BPM: 142 (0x8E)
        let payload = Data([0x00, 0x8E])
        let (measurement, samples) = try parser.parse(payload: payload)

        XCTAssertEqual(measurement.beatsPerMinute, 142)
        XCTAssertEqual(samples.count, 1)
        if case .heartRate(let bpm, _) = samples[0] {
            XCTAssertEqual(bpm, 142)
        } else {
            XCTFail("Expected .heartRate sample")
        }
    }

    func test_parse16BitHeartRate() throws {
        // Flags: 0x01 (16-bit HR), BPM: 260 (0x0104 -> [0x04, 0x01])
        let payload = Data([0x01, 0x04, 0x01])
        let (measurement, samples) = try parser.parse(payload: payload)

        XCTAssertEqual(measurement.beatsPerMinute, 260)
        XCTAssertEqual(samples.count, 1)
        if case .heartRate(let bpm, _) = samples[0] {
            XCTAssertEqual(bpm, 260)
        } else {
            XCTFail("Expected .heartRate sample")
        }
    }

    func test_parseContactAndEnergyAndRRIntervals() throws {
        // Flags: 0x1E (8-bit HR, Contact Supported & Detected: 0x06, Energy: 0x08, RR: 0x10)
        // HR: 130 (0x82)
        // Energy: 500 J (0x01F4 -> [0xF4, 0x01])
        // RR: 1024 ticks = 1.0s (0x0400 -> [0x00, 0x04])
        let payload = Data([0x1E, 0x82, 0xF4, 0x01, 0x00, 0x04])
        let (measurement, _) = try parser.parse(payload: payload)

        XCTAssertEqual(measurement.beatsPerMinute, 130)
        XCTAssertEqual(measurement.sensorContactDetected, true)
        XCTAssertEqual(measurement.energyExpendedJoules, 500)
        XCTAssertEqual(measurement.rrIntervals.count, 1)
        XCTAssertEqual(measurement.rrIntervals[0], 1.0, accuracy: 0.001)
    }

    func test_emptyPayload_throwsError() {
        XCTAssertThrowsError(try parser.parse(payload: Data()))
    }
}
