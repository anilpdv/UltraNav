import XCTest
import CoreBluetooth
@testable import UltraNav

@MainActor
final class BluetoothServiceConnectionTests: XCTestCase {
    func testConnectToUnknownSensorThrows() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let unknownID = SensorIdentifier(rawValue: "unknown-01")
        do {
            try await service.connect(to: unknownID)
            XCTFail("Expected connect to throw unknownSensor")
        } catch {
            XCTAssertEqual(error as? SensorServiceFailure, .unknownSensor(unknownID))
        }
    }

    func testConnectCallsCentralAndEmitsConnecting() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let peripheral = FakePeripheral(identifier: UUID(), name: "Stages Power")
        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.cyclingPower]
            ],
            rssi: NSNumber(value: -60)
        )

        let sensorID = SensorIdentifier(rawValue: peripheral.identifier.uuidString)

        let exp = expectation(description: "Connecting state emitted")
        let task = Task {
            for await event in service.events {
                if case .connectionStateChanged(let id, let state) = event, id == sensorID, state == .connecting {
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        try await service.connect(to: sensorID)

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()

        XCTAssertEqual(fakeCentral.connectedPeripherals.count, 1)
        XCTAssertEqual(fakeCentral.connectedPeripherals.first?.identifier, peripheral.identifier)
    }

    func testPeripheralConnectedTriggersServiceDiscovery() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

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

        let exp = expectation(description: "Discovered services state emitted")
        let task = Task {
            for await event in service.events {
                if case .connectionStateChanged(let id, let state) = event, id == sensorID, state == .discoveringServices {
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        service.peripheralConnected(peripheral)

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()

        XCTAssertEqual(peripheral.discoverServicesCalls.count, 1)
        XCTAssertEqual(peripheral.discoverServicesCalls.first, [CoreBluetoothServiceUUID.heartRate])
    }

    func testPeripheralConnectionFailedEmitsFailure() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let peripheral = FakePeripheral(identifier: UUID(), name: "Failed Sensor")
        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.heartRate]
            ],
            rssi: NSNumber(value: -60)
        )

        let sensorID = SensorIdentifier(rawValue: peripheral.identifier.uuidString)
        try await service.connect(to: sensorID)

        let exp = expectation(description: "Connection failed event")
        let task = Task {
            for await event in service.events {
                if case .failed(let failure) = event, failure == .connectionFailed(sensorID) {
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        service.peripheralConnectionFailed(peripheral, error: NSError(domain: "CBErrorDomain", code: 1))

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }
}
