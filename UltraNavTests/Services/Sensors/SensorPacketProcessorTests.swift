import XCTest
@testable import UltraNav

final class SensorPacketProcessorTests: XCTestCase {
    private var processor: SensorPacketProcessor!

    override func setUp() {
        super.setUp()
        processor = SensorPacketProcessor()
    }

    func test_routesHeartRatePacket() async throws {
        let sensor = SensorIdentifier(rawValue: "HR-1")
        let packet = SensorMeasurementPacket(
            sensor: sensor,
            serviceIdentifier: "180D",
            characteristicIdentifier: "2A37",
            payload: Data([0x00, 0x96]), // 150 BPM
            receivedAt: Date()
        )

        let samples = try await processor.parse(packet)
        XCTAssertEqual(samples.count, 1)
        if case .heartRate(let bpm, _) = samples[0] {
            XCTAssertEqual(bpm, 150)
        } else {
            XCTFail("Expected heart rate sample")
        }
    }

    func test_routesCyclingPowerPacket() async throws {
        let sensor = SensorIdentifier(rawValue: "PWR-1")
        let packet = SensorMeasurementPacket(
            sensor: sensor,
            serviceIdentifier: "1818",
            characteristicIdentifier: "2A63",
            payload: Data([0x00, 0x00, 0x2C, 0x01]), // 300W
            receivedAt: Date()
        )

        let samples = try await processor.parse(packet)
        XCTAssertEqual(samples.count, 1)
        if case .power(let watts, _) = samples[0] {
            XCTAssertEqual(watts, 300)
        } else {
            XCTFail("Expected power sample")
        }
    }

    func test_maintainsIndependentStateAcrossSensors() async throws {
        let sensor1 = SensorIdentifier(rawValue: "CSC-1")
        let sensor2 = SensorIdentifier(rawValue: "CSC-2")

        let p1_s1 = SensorMeasurementPacket(
            sensor: sensor1,
            serviceIdentifier: "1816",
            characteristicIdentifier: "2A5B",
            payload: Data([0x02, 0x64, 0x00, 0x00, 0x04]),
            receivedAt: Date()
        )
        let p1_s2 = SensorMeasurementPacket(
            sensor: sensor2,
            serviceIdentifier: "1816",
            characteristicIdentifier: "2A5B",
            payload: Data([0x02, 0xC8, 0x00, 0x00, 0x04]),
            receivedAt: Date()
        )

        _ = try await processor.parse(p1_s1)
        _ = try await processor.parse(p1_s2)

        let p2_s1 = SensorMeasurementPacket(
            sensor: sensor1,
            serviceIdentifier: "1816",
            characteristicIdentifier: "2A5B",
            payload: Data([0x02, 0x66, 0x00, 0x00, 0x08]), // +2 revs in 1s = 120 RPM
            receivedAt: Date()
        )
        let samples1 = try await processor.parse(p2_s1)

        XCTAssertEqual(samples1.count, 1)
        if case .cadence(let rpm, _) = samples1[0] {
            XCTAssertEqual(rpm, 120.0, accuracy: 1.0)
        }
    }
}
