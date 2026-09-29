import XCTest
@testable import UltraNav

final class CSCMeasurementParserTests: XCTestCase {
    private var parser: CSCMeasurementParser!

    override func setUp() {
        super.setUp()
        parser = CSCMeasurementParser()
    }

    func test_wheelSpeedCalculation() async throws {
        // Flags: 0x01 (Wheel Present)
        // Packet 1: Wheel Rev = 1000 [0xE8, 0x03, 0x00, 0x00], Wheel Time = 1024 [0x00, 0x04]
        let p1 = Data([0x01, 0xE8, 0x03, 0x00, 0x00, 0x00, 0x04])
        _ = try await parser.parse(payload: p1)

        // Packet 2: Wheel Rev = 1005 (+5 revs * 2.105m = 10.525m), Wheel Time = 2048 (+1024 ticks = 1.0s) -> 10.525 m/s
        let p2 = Data([0x01, 0xED, 0x03, 0x00, 0x00, 0x00, 0x08])
        let (_, s2) = try await parser.parse(payload: p2)

        XCTAssertEqual(s2.count, 1)
        if case .speed(let mps, _) = s2[0] {
            XCTAssertEqual(mps, 10.525, accuracy: 0.05)
        } else {
            XCTFail("Expected .speed sample")
        }
    }

    func test_crankCadenceCalculation() async throws {
        // Flags: 0x02 (Crank Present)
        // Packet 1: Crank Rev = 200 [0xC8, 0x00], Crank Time = 1024 [0x00, 0x04]
        let p1 = Data([0x02, 0xC8, 0x00, 0x00, 0x04])
        _ = try await parser.parse(payload: p1)

        // Packet 2: Crank Rev = 203 (+3 revs), Crank Time = 3072 (+2048 ticks = 2.0s) -> 3 rev / 2s * 60 = 90 RPM
        let p2 = Data([0x02, 0xCB, 0x00, 0x00, 0x0C])
        let (_, s2) = try await parser.parse(payload: p2)

        XCTAssertEqual(s2.count, 1)
        if case .cadence(let rpm, _) = s2[0] {
            XCTAssertEqual(rpm, 90.0, accuracy: 1.0)
        } else {
            XCTFail("Expected .cadence sample")
        }
    }

    func test_combinedWheelAndCrankCalculation() async throws {
        // Flags: 0x03 (Wheel & Crank Present)
        // Packet 1: Wheel = 100, WheelTime = 1024, Crank = 50, CrankTime = 1024
        let p1 = Data([0x03, 0x64, 0x00, 0x00, 0x00, 0x00, 0x04, 0x32, 0x00, 0x00, 0x04])
        _ = try await parser.parse(payload: p1)

        // Packet 2: Wheel = 105 (+5 revs), WheelTime = 2048 (+1s), Crank = 52 (+2 revs), CrankTime = 2048 (+1s)
        let p2 = Data([0x03, 0x69, 0x00, 0x00, 0x00, 0x00, 0x08, 0x34, 0x00, 0x00, 0x08])
        let (_, s2) = try await parser.parse(payload: p2)

        XCTAssertEqual(s2.count, 2)
    }

    func test_wheel32BitRolloverHandling() async throws {
        // Packet 1: Near 32-bit max (4294967290 = 0xFFFFFFFA), Time = 1024 [0x00, 0x04]
        let p1 = Data([0x01, 0xFA, 0xFF, 0xFF, 0xFF, 0x00, 0x04])
        _ = try await parser.parse(payload: p1)

        // Packet 2: Rolled over to 4 (+10 revs * 2.105m = 21.05m), Time = 3072 (+2.0s) -> 10.525 m/s
        let p2 = Data([0x01, 0x04, 0x00, 0x00, 0x00, 0x00, 0x0C])
        let (_, s2) = try await parser.parse(payload: p2)

        XCTAssertEqual(s2.count, 1)
        if case .speed(let mps, _) = s2[0] {
            XCTAssertEqual(mps, 10.525, accuracy: 0.05)
        } else {
            XCTFail("Expected .speed sample")
        }
    }
}
