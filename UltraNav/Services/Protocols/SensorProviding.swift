import Foundation

/// Abstract interface for Bluetooth Low Energy cycling sensors.
@MainActor
protocol SensorProviding: AnyObject {
    var livePower: Int? { get }
    var liveCadence: Int? { get }
    var liveSpeedKmh: Double? { get }
    var liveHeartRate: Int? { get }
    var sensorBatteryLevel: Int? { get }
    var isScanning: Bool { get }

    func startScanning()
    func stopScanning()
}
