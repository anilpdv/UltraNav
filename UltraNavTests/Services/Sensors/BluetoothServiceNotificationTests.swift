import XCTest
import CoreBluetooth
@testable import UltraNav

@MainActor
final class BluetoothServiceNotificationTests: XCTestCase {
    func testServiceDiscoveryFailureEmitsFailure() async throws {
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

        let exp = expectation(description: "Service discovery failed")
        let task = Task {
            for await event in service.events {
                if case .failed(let failure) = event, failure == .serviceDiscoveryFailed(sensorID) {
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        service.peripheral(peripheral, discoveredServicesWith: NSError(domain: "CBErrorDomain", code: 2))

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }

    func testServiceDiscoveryWithNoSupportedServicesEmitsFailure() async throws {
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

        let exp = expectation(description: "Required service missing")
        let task = Task {
            for await event in service.events {
                if case .failed(let failure) = event {
                    if case .requiredServiceMissing(let id, _) = failure, id == sensorID {
                        exp.fulfill()
                        break
                    }
                }
            }
        }

        await Task.yield()
        // No services on peripheral
        peripheral.services = []
        service.peripheral(peripheral, discoveredServicesWith: nil)

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }
}
