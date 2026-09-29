import XCTest
@testable import UltraNav

final class CyclingPowerMeasurementParserTests: XCTestCase {
    private var parser: CyclingPowerMeasurementParser!

    override func setUp() {
        super.setUp()
        parser = CyclingPowerMeasurementParser()
    }

    func test_parseInstantaneousPowerOnly() async throws {
        // Flags: 0x0000, Power: 250W (0x00FA -> [0xFA, 0x00])
        let payload = Data([0x00, 0x00, 0xFA, 0x00])
        let (measurement, samples) = try await parser.parse(payload: payload)

        XCTAssertEqual(measurement.instantaneousPowerWatts, 250)
        XCTAssertEqual(samples.count, 1)
        if case .power(let watts, _) = samples[0] {
            XCTAssertEqual(watts, 250)
        } else {
            XCTFail("Expected .power sample")
        }
    }

    func test_parseCyclingPowerWithCrankRevolutionData() async throws {
        // Flags: 0x0020 (Crank Data Present), Power: 200W (0x00C8 -> [0xC8, 0x00])
        // Packet 1: Crank Revs = 100 [0x64, 0x00], Crank Time = 1024 (1.0s) [0x00, 0x04]
        let p1 = Data([0x20, 0x00, 0xC8, 0x00, 0x64, 0x00, 0x00, 0x04])
        let (_, s1) = try await parser.parse(payload: p1)
        // First packet establishes baseline
        XCTAssertEqual(s1.count, 1)

        // Packet 2: Crank Revs = 102 (+2 revs), Crank Time = 2048 (+1024 ticks = 1.0s) -> 2 rev / 1s * 60 = 120 RPM
        // 102 = 0x0066 -> [0x66, 0x00], 2048 = 0x0800 -> [0x00, 0x08]
        let p2 = Data([0x20, 0x00, 0xD0, 0x00, 0x66, 0x00, 0x00, 0x08])
        let (_, s2) = try await parser.parse(payload: p2)

        XCTAssertEqual(s2.count, 2)
        if case .cadence(let rpm, _) = s2[1] {
            XCTAssertEqual(rpm, 120.0, accuracy: 1.0)
        } else {
            XCTFail("Expected .cadence sample")
        }
    }

    func test_crankRolloverHandling() async throws {
        // Packet 1: Near 16-bit max (65534 = 0xFFFE -> [0xFE, 0xFF]), Time: 65000 [0xE8, 0xFD]
        let p1 = Data([0x20, 0x00, 0xC8, 0x00, 0xFE, 0xFF, 0xE8, 0xFD])
        _ = try await parser.parse(payload: p1)

        // Packet 2: Wrapped past 65535 to 2 (+4 revs), Time: 65000 + 2048 ticks (2.0s) = 1512 [0xE8, 0x05]
        let p2 = Data([0x20, 0x00, 0xC8, 0x00, 0x02, 0x00, 0xE8, 0x05])
        let (_, s2) = try await parser.parse(payload: p2)

        // 4 revs in 2.0s = 120 RPM
        XCTAssertEqual(s2.count, 2)
        if case .cadence(let rpm, _) = s2[1] {
            XCTAssertEqual(rpm, 120.0, accuracy: 1.0)
        } else {
            XCTFail("Expected .cadence sample")
        }
    }
}
