import XCTest
@testable import UltraNav

final class FakeSensorProviderTests: XCTestCase {
    func testSensorFakeDeliversInjectedEvent() async {
        let provider = FakeSensorProvider()
        let sensorId = SensorIdentifier(rawValue: "hrm-01")
        let received = expectation(description: "Sensor connected event received")

        let task = Task {
            for await event in provider.events {
                if case .connectionStateChanged(let id, let state) = event, id == sensorId, state == .connected {
                    received.fulfill()
                    break
                }
            }
        }

        await Task.yield()
        await provider.send(.connectionStateChanged(sensor: sensorId, state: .connected))

        await fulfillment(of: [received], timeout: 1.0)
        task.cancel()
    }

    func testSensorFakeTracksScanAndConnectCalls() async throws {
        let provider = FakeSensorProvider()
        let sensorId = SensorIdentifier(rawValue: "power-01")

        try await provider.startScanning(for: [.cyclingPower, .heartRate])
        let scanCount = await provider.startScanningCallCount
        let scannedTypes = await provider.scannedTypes
        XCTAssertEqual(scanCount, 1)
        XCTAssertEqual(scannedTypes, [.cyclingPower, .heartRate])

        try await provider.connect(to: sensorId)
        let connected = await provider.connectedSensors
        XCTAssertEqual(connected, [sensorId])

        await provider.disconnect(from: sensorId)
        let disconnected = await provider.disconnectedSensors
        XCTAssertEqual(disconnected, [sensorId])

        await provider.stopScanning()
        let stopCount = await provider.stopScanningCallCount
        XCTAssertEqual(stopCount, 1)

        await provider.disconnectAll()
        let discAllCount = await provider.disconnectAllCallCount
        XCTAssertEqual(discAllCount, 1)
    }

    func testSensorFakeThrowsConfiguredFailures() async {
        let provider = FakeSensorProvider()
        let sensorId = SensorIdentifier(rawValue: "cadence-01")

        await provider.setScanFailure(.bluetoothUnavailable(.poweredOff))
        do {
            try await provider.startScanning(for: [.cyclingCadence])
            XCTFail("Expected startScanning to throw")
        } catch {
            XCTAssertEqual(error as? SensorServiceFailure, .bluetoothUnavailable(.poweredOff))
        }

        await provider.setConnectionFailure(.connectionFailed(sensorId), for: sensorId)
        do {
            try await provider.connect(to: sensorId)
            XCTFail("Expected connect to throw")
        } catch {
            XCTAssertEqual(error as? SensorServiceFailure, .connectionFailed(sensorId))
        }
    }
}
