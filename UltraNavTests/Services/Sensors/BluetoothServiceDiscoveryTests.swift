import XCTest
import CoreBluetooth
@testable import UltraNav

@MainActor
final class BluetoothServiceDiscoveryTests: XCTestCase {
    func testDiscoveredPeripheralEmitsSensorDiscoveredEvent() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let exp = expectation(description: "Sensor discovered event")
        let peripheral = FakePeripheral(identifier: UUID(), name: "Wahoo TICKR")

        let task = Task {
            for await event in service.events {
                if case .sensorDiscovered(let discovery) = event {
                    XCTAssertEqual(discovery.descriptor.name, "Wahoo TICKR")
                    XCTAssertEqual(discovery.descriptor.supportedTypes, [.heartRate])
                    XCTAssertEqual(discovery.signalStrength, -65)
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.heartRate],
                CBAdvertisementDataLocalNameKey: "Wahoo TICKR"
            ],
            rssi: NSNumber(value: -65)
        )

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()

        let known = await service.knownSensors()
        XCTAssertEqual(known.count, 1)
        XCTAssertEqual(known.first?.name, "Wahoo TICKR")
    }

    func testDiscoveredPeripheralWithMultipleServices() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let exp = expectation(description: "CSC sensor discovered")
        let peripheral = FakePeripheral(identifier: UUID(), name: "Speed & Cadence")

        let task = Task {
            for await event in service.events {
                if case .sensorDiscovered(let discovery) = event {
                    XCTAssertTrue(discovery.descriptor.supportedTypes.contains(.cyclingSpeed))
                    XCTAssertTrue(discovery.descriptor.supportedTypes.contains(.cyclingCadence))
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.cyclingSpeedAndCadence]
            ],
            rssi: NSNumber(value: -70)
        )

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }

    func testUnsupportedPeripheralIsIgnored() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let peripheral = FakePeripheral(identifier: UUID(), name: "Unsupported TV")
        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CBUUID(string: "FFFF")]
            ],
            rssi: NSNumber(value: -80)
        )

        let known = await service.knownSensors()
        XCTAssertEqual(known.count, 0)
    }

    func testDuplicateDiscoveryDoesNotDuplicateContext() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let uuid = UUID()
        let peripheral = FakePeripheral(identifier: uuid, name: "Initial Name")

        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.heartRate]
            ],
            rssi: NSNumber(value: -70)
        )

        // Second discovery with updated name
        service.peripheralDiscovered(
            peripheral,
            advertisementData: [
                CBAdvertisementDataServiceUUIDsKey: [CoreBluetoothServiceUUID.heartRate],
                CBAdvertisementDataLocalNameKey: "Updated Name"
            ],
            rssi: NSNumber(value: -60)
        )

        let known = await service.knownSensors()
        XCTAssertEqual(known.count, 1)
        XCTAssertEqual(known.first?.name, "Updated Name")
    }
}
