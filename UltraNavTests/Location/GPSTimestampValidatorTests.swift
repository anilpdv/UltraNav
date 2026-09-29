import XCTest
@testable import UltraNav

final class GPSTimestampValidatorTests: XCTestCase {
    private var validator: GPSTimestampValidator!
    private var config: GPSProcessingConfiguration!

    override func setUp() {
        super.setUp()
        validator = GPSTimestampValidator()
        config = GPSProcessingConfiguration(
            maximumSampleAgeSeconds: 15.0,
            minimumTimeDeltaSeconds: 0.25
        )
    }

    func testValidTimestampPasses() {
        let now = Date(timeIntervalSince1970: 1700000010)
        let sampleTime = Date(timeIntervalSince1970: 1700000008) // 2s old
        let prevTime = Date(timeIntervalSince1970: 1700000007)

        let result = validator.validate(
            sampleTimestamp: sampleTime,
            receivedAt: now,
            previousAcceptedTimestamp: prevTime,
            configuration: config
        )

        XCTAssertEqual(result, .valid)
    }

    func testTooOldTimestampRejected() {
        let now = Date(timeIntervalSince1970: 1700000100)
        let sampleTime = Date(timeIntervalSince1970: 1700000000) // 100s old

        let result = validator.validate(
            sampleTimestamp: sampleTime,
            receivedAt: now,
            previousAcceptedTimestamp: nil,
            configuration: config
        )

        if case .tooOld(let age) = result {
            XCTAssertEqual(age, 100.0, accuracy: 0.001)
        } else {
            XCTFail("Expected tooOld result, got: \(result)")
        }
    }

    func testOutOfOrderTimestampRejected() {
        let now = Date(timeIntervalSince1970: 1700000010)
        let prevTime = Date(timeIntervalSince1970: 1700000008)
        let sampleTime = Date(timeIntervalSince1970: 1700000005) // Out of order!

        let result = validator.validate(
            sampleTimestamp: sampleTime,
            receivedAt: now,
            previousAcceptedTimestamp: prevTime,
            configuration: config
        )

        XCTAssertEqual(result, .outOfOrder)
    }

    func testDuplicateTimestampRejected() {
        let now = Date(timeIntervalSince1970: 1700000010)
        let prevTime = Date(timeIntervalSince1970: 1700000008)
        let sampleTime = Date(timeIntervalSince1970: 1700000008) // Duplicate!

        let result = validator.validate(
            sampleTimestamp: sampleTime,
            receivedAt: now,
            previousAcceptedTimestamp: prevTime,
            configuration: config
        )

        XCTAssertEqual(result, .duplicate)
    }

    func testInsufficientDeltaRejected() {
        let now = Date(timeIntervalSince1970: 1700000010)
        let prevTime = Date(timeIntervalSince1970: 1700000008.0)
        let sampleTime = Date(timeIntervalSince1970: 1700000008.1) // 0.1s delta < 0.25s

        let result = validator.validate(
            sampleTimestamp: sampleTime,
            receivedAt: now,
            previousAcceptedTimestamp: prevTime,
            configuration: config
        )

        XCTAssertEqual(result, .insufficientDelta)
    }
}
