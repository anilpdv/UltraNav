import Foundation
@testable import UltraNav

/// Controllable fake sensor service for unit tests.
@MainActor
public final class FakeSensorService: SensorProviding {
    public var livePower: Int?
    public var liveCadence: Int?
    public var liveSpeedKmh: Double?
    public var liveHeartRate: Int?
    public var sensorBatteryLevel: Int?
    public var isScanning: Bool = false

    public init() {}

    public func startScanning() {
        isScanning = true
    }

    public func stopScanning() {
        isScanning = false
    }

    public func simulatePower(_ watts: Int) {
        self.livePower = watts
    }

    public func simulateHeartRate(_ bpm: Int) {
        self.liveHeartRate = bpm
    }

    public func simulateCadence(_ rpm: Int) {
        self.liveCadence = rpm
    }

    public func simulateSpeed(_ kmh: Double) {
        self.liveSpeedKmh = kmh
    }
}
