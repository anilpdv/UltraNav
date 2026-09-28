import XCTest
import CoreBluetooth
@testable import UltraNav

@MainActor
final class BluetoothServiceDisconnectionTests: XCTestCase {
    func testExplicitDisconnectCancelsCentralConnection() async throws {
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
        service.peripheralConnected(peripheral)

        let exp = expectation(description: "Disconnecting state emitted")
        let task = Task {
            for await event in service.events {
                if case .connectionStateChanged(let id, let state) = event, id == sensorID, state == .disconnecting {
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        await service.disconnect(from: sensorID)

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()

        XCTAssertEqual(fakeCentral.cancelledPeripherals.count, 1)
    }

    func testExplicitDisconnectCallbackDoesNotEmitUnexpectedFailure() async throws {
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
        service.peripheralConnected(peripheral)

        await service.disconnect(from: sensorID)

        let exp = expectation(description: "Disconnected state emitted")
        var receivedUnexpectedFailure = false

        let task = Task {
            for await event in service.events {
                if case .connectionStateChanged(let id, let state) = event, id == sensorID, state == .disconnected {
                    exp.fulfill()
                    break
                }
                if case .failed(let failure) = event, failure == .disconnectedUnexpectedly(sensorID) {
                    receivedUnexpectedFailure = true
                }
            }
        }

        await Task.yield()
        service.peripheralDisconnected(peripheral, error: nil)

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()

        XCTAssertFalse(receivedUnexpectedFailure)
    }

    func testUnexpectedDisconnectEmitsTypedFailure() async throws {
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
        service.peripheralConnected(peripheral)

        let exp = expectation(description: "Unexpected disconnect event")
        let task = Task {
            for await event in service.events {
                if case .failed(let failure) = event, failure == .disconnectedUnexpectedly(sensorID) {
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        service.peripheralDisconnected(peripheral, error: NSError(domain: "CBErrorDomain", code: 6))

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }

    func testDisconnectAllCancelsAllActiveConnections() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let p1 = FakePeripheral(identifier: UUID(), name: "HR 1")
        let p2 = FakePeripheral(identifier: UUID(), name: "Power 2")

        service.peripheralDiscovered(p1, advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.heartRate]], rssi: NSNumber(value: -60))
        service.peripheralDiscovered(p2, advertisementData: [CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.cyclingPower]], rssi: NSNumber(value: -60))

        try await service.connect(to: SensorIdentifier(rawValue: p1.identifier.uuidString))
        try await service.connect(to: SensorIdentifier(rawValue: p2.identifier.uuidString))

        await service.disconnectAll()

        XCTAssertEqual(fakeCentral.cancelledPeripherals.count, 2)
    }
}
