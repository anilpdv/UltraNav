import XCTest
import CoreBluetooth
@testable import UltraNav

@MainActor
final class BluetoothServiceFailureTests: XCTestCase {
    func testLegacyHeartRateParserAdapterParses8BitData() async throws {
        let adapter = LegacyHeartRateParserAdapter()
        let packet = SensorFactory.makeHRPacket(sensorId: "hrm-01", bpm: 152)

        let samples = try await adapter.parse(packet)
        XCTAssertEqual(samples.count, 1)
        if case .heartRate(let bpm, _) = samples.first {
            XCTAssertEqual(bpm, 152)
        } else {
            XCTFail("Expected heart rate sample")
        }
    }

    func testLegacyHeartRateParserAdapterRejectsEmptyData() async {
        let adapter = LegacyHeartRateParserAdapter()
        let emptyPacket = SensorMeasurementPacket(
            sensor: SensorIdentifier(rawValue: "hrm-01"),
            serviceIdentifier: "180D",
            characteristicIdentifier: "2A37",
            payload: Data(),
            receivedAt: Date()
        )

        do {
            _ = try await adapter.parse(emptyPacket)
            XCTFail("Expected empty payload to throw")
        } catch {
            XCTAssertEqual(error as? SensorPacketParsingFailure, .emptyPayload)
        }
    }

    func testLegacyCyclingPowerParserAdapterParsesWatts() async throws {
        let adapter = LegacyCyclingPowerParserAdapter()
        let packet = SensorFactory.makePowerPacket(sensorId: "power-01", watts: 280)

        let samples = try await adapter.parse(packet)
        XCTAssertEqual(samples.count, 1)
        if case .power(let watts, _) = samples.first {
            XCTAssertEqual(watts, 280)
        } else {
            XCTFail("Expected power sample")
        }
    }

    func testParserFailureDoesNotCrashOrDisconnect() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let fakeParser = FakeSensorPacketParser()
        await fakeParser.setFailure(.invalidMeasurement)

        let service = BluetoothService(central: fakeCentral, packetParser: fakeParser)

        let peripheral = FakePeripheral(identifier: UUID(), name: "Wahoo HR")
        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.heartRate]
            ],
            rssi: NSNumber(value: -60)
        )

        let sensorID = SensorIdentifier(rawValue: peripheral.identifier.uuidString)
        try await service.connect(to: sensorID)
        service.peripheralConnected(peripheral)

        let exp = expectation(description: "Malformed measurement event")
        let task = Task {
            for await event in service.events {
                if case .failed(let failure) = event {
                    if case .malformedMeasurement(let id, let char) = failure, id == sensorID, char == "2A37" {
                        exp.fulfill()
                        break
                    }
                }
            }
        }

        await Task.yield()

        let char = FakeCharacteristic(
            uuid: CoreBluetoothCharacteristicUUID.heartRateMeasurement,
            value: Data([0x00, 0x55]),
            isNotifying: true,
            properties: [.notify]
        )
        service.peripheral(peripheral, updatedValueFor: char, error: nil)

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }
}
