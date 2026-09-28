import XCTest
import CoreBluetooth
@testable import UltraNav

@MainActor
final class BluetoothServiceAvailabilityTests: XCTestCase {
    func testInitialAvailabilityMatchesCentralState() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        let isAvailable = await service.isAvailable()
        XCTAssertTrue(isAvailable)
        XCTAssertEqual(service.availability, .poweredOn)
    }

    func testAvailabilityStateChangeEmitsEvent() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOff)
        let bridge = CoreBluetoothDelegateBridge()
        let service = BluetoothService(central: fakeCentral, centralDelegateBridge: bridge)

        let exp = expectation(description: "Availability changed event")
        let task = Task {
            for await event in service.events {
                if case .availabilityChanged(let status) = event, status == .poweredOn {
                    exp.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        fakeCentral.setState(.poweredOn)
        service.bluetoothStateChanged(.poweredOn)

        await fulfillment(of: [exp], timeout: 1.0)
        task.cancel()
    }

    func testScanningWhileUnavailableThrows() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOff)
        let service = BluetoothService(central: fakeCentral)

        do {
            try await service.startScanning(for: [.heartRate])
            XCTFail("Expected startScanning to throw")
        } catch {
            XCTAssertEqual(error as? SensorServiceFailure, .bluetoothUnavailable(.poweredOff))
        }
    }

    func testConnectingWhileUnavailableThrows() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.unauthorized)
        let service = BluetoothService(central: fakeCentral)

        do {
            try await service.connect(to: SensorIdentifier(rawValue: "hrm-01"))
            XCTFail("Expected connect to throw")
        } catch {
            XCTAssertEqual(error as? SensorServiceFailure, .bluetoothUnavailable(.unauthorized))
        }
    }

    func testBluetoothLossStopsActiveScan() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        try await service.startScanning(for: [.heartRate])
        XCTAssertEqual(service.scanState, .scanning)

        service.bluetoothStateChanged(.poweredOff)
        XCTAssertEqual(service.scanState, .idle)
        XCTAssertEqual(fakeCentral.stopScanCallCount, 1)
    }
}
