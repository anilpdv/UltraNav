import XCTest
import CoreBluetooth
@testable import UltraNav

@MainActor
final class BluetoothServiceScanningTests: XCTestCase {
    func testStartScanningRequestsFilteredUUIDs() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        try await service.startScanning(for: [.heartRate])
        XCTAssertEqual(fakeCentral.scanRequests.count, 1)
        XCTAssertEqual(fakeCentral.scanRequests.first, [CoreBluetoothServiceUUID.heartRate])
        XCTAssertEqual(service.scanState, .scanning)
    }

    func testStartScanningWithCombinedTypes() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        try await service.startScanning(for: [.heartRate, .cyclingPower, .cyclingSpeed])
        XCTAssertEqual(fakeCentral.scanRequests.count, 1)
        XCTAssertEqual(fakeCentral.scanRequests.first??.count, 3)
    }

    func testEmptyScanRequestThrowsInvalidServiceState() async {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        do {
            try await service.startScanning(for: [])
            XCTFail("Expected empty scan to throw")
        } catch {
            XCTAssertEqual(error as? SensorServiceFailure, .invalidServiceState)
        }
    }

    func testDuplicateStartScanIsIdempotent() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        try await service.startScanning(for: [.heartRate])
        try await service.startScanning(for: [.heartRate])
        XCTAssertEqual(fakeCentral.scanRequests.count, 1)
    }

    func testStopScanningStopsCentralAndResetsState() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        try await service.startScanning(for: [.heartRate])
        await service.stopScanning()

        XCTAssertEqual(service.scanState, .idle)
        XCTAssertEqual(fakeCentral.stopScanCallCount, 1)

        // Repeated stop is safe
        await service.stopScanning()
        XCTAssertEqual(fakeCentral.stopScanCallCount, 1)
    }

    func testScanCanRestartAfterStopping() async throws {
        let fakeCentral = FakeCentralManager()
        fakeCentral.setState(.poweredOn)
        let service = BluetoothService(central: fakeCentral)

        try await service.startScanning(for: [.heartRate])
        await service.stopScanning()
        try await service.startScanning(for: [.cyclingPower])

        XCTAssertEqual(service.scanState, .scanning)
        XCTAssertEqual(fakeCentral.scanRequests.count, 2)
    }
}
