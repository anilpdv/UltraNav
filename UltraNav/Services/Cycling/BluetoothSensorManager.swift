import Foundation
@preconcurrency import CoreBluetooth
import OSLog

// Standard Bluetooth SIG 16-bit UUID constants
private nonisolated(unsafe) let kPowerServiceUUID = CBUUID(string: "1818")
private nonisolated(unsafe) let kPowerMeasurementCharUUID = CBUUID(string: "2A63")

private nonisolated(unsafe) let kCscServiceUUID = CBUUID(string: "1816") // Cycling Speed & Cadence
private nonisolated(unsafe) let kCscMeasurementCharUUID = CBUUID(string: "2A5B")

private nonisolated(unsafe) let kHrServiceUUID = CBUUID(string: "180D") // Heart Rate
private nonisolated(unsafe) let kHrMeasurementCharUUID = CBUUID(string: "2A37")

private nonisolated(unsafe) let kBatteryServiceUUID = CBUUID(string: "180F")
private nonisolated(unsafe) let kBatteryLevelCharUUID = CBUUID(string: "2A19")

public struct DiscoveredSensor: Identifiable, Equatable {
    public let id: UUID
    public let peripheral: CBPeripheral
    public let name: String
    public let rssi: Int
    public var isConnected: Bool

    public static func == (lhs: DiscoveredSensor, rhs: DiscoveredSensor) -> Bool {
        lhs.id == rhs.id && lhs.isConnected == rhs.isConnected
    }
}

/// Central manager for standard Bluetooth LE cycling sensors (Power Meter, Cadence, Speed, Heart Rate).
@MainActor
@Observable
public final class BluetoothSensorManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    public static let shared = BluetoothSensorManager()

    // Observable Live Data
    public var livePower: Int?
    public var liveCadence: Int?
    public var liveSpeedKmh: Double?
    public var liveHeartRate: Int?
    public var sensorBatteryLevel: Int?

    public var isScanning: Bool = false
    public var discoveredSensors: [DiscoveredSensor] = []
    public var connectedSensors: [CBPeripheral] = []

    private var centralManager: CBCentralManager?
    private var lastWheelRevolutions: UInt32?
    private var lastWheelEventTime: UInt16?
    private var lastCrankRevolutions: UInt16?
    private var lastCrankEventTime: UInt16?

    public override init() {
        super.init()
    }

    public func startScanning() {
        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: nil)
        }
        guard let central = centralManager, central.state == .poweredOn else {
            isScanning = true
            return
        }
        isScanning = true
        central.scanForPeripherals(
            withServices: [kPowerServiceUUID, kCscServiceUUID, kHrServiceUUID],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
    }

    public func stopScanning() {
        isScanning = false
        centralManager?.stopScan()
    }

    public func connect(sensor: DiscoveredSensor) {
        centralManager?.connect(sensor.peripheral, options: nil)
    }

    public func disconnect(sensor: DiscoveredSensor) {
        centralManager?.cancelPeripheralConnection(sensor.peripheral)
    }

    // MARK: - CBCentralManagerDelegate

    nonisolated public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            if central.state == .poweredOn && self.isScanning {
                central.scanForPeripherals(
                    withServices: [kPowerServiceUUID, kCscServiceUUID, kHrServiceUUID],
                    options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
                )
            }
        }
    }

    nonisolated public func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Cycling Sensor"
        let rssiVal = RSSI.intValue
        Task { @MainActor in
            if !self.discoveredSensors.contains(where: { $0.id == peripheral.identifier }) {
                let sensor = DiscoveredSensor(
                    id: peripheral.identifier,
                    peripheral: peripheral,
                    name: name,
                    rssi: rssiVal,
                    isConnected: peripheral.state == .connected
                )
                self.discoveredSensors.append(sensor)
            }
        }
    }

    nonisolated public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            peripheral.delegate = self
            if !self.connectedSensors.contains(where: { $0.identifier == peripheral.identifier }) {
                self.connectedSensors.append(peripheral)
            }
            if let idx = self.discoveredSensors.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.discoveredSensors[idx].isConnected = true
            }
            peripheral.discoverServices([
                kPowerServiceUUID,
                kCscServiceUUID,
                kHrServiceUUID,
                kBatteryServiceUUID
            ])
        }
    }

    nonisolated public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        Task { @MainActor in
            self.connectedSensors.removeAll(where: { $0.identifier == peripheral.identifier })
            if let idx = self.discoveredSensors.firstIndex(where: { $0.id == peripheral.identifier }) {
                self.discoveredSensors[idx].isConnected = false
            }
        }
    }

    // MARK: - CBPeripheralDelegate

    nonisolated public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid == kPowerServiceUUID {
                peripheral.discoverCharacteristics([kPowerMeasurementCharUUID], for: service)
            } else if service.uuid == kCscServiceUUID {
                peripheral.discoverCharacteristics([kCscMeasurementCharUUID], for: service)
            } else if service.uuid == kHrServiceUUID {
                peripheral.discoverCharacteristics([kHrMeasurementCharUUID], for: service)
            } else if service.uuid == kBatteryServiceUUID {
                peripheral.discoverCharacteristics([kBatteryLevelCharUUID], for: service)
            }
        }
    }

    nonisolated public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for char in characteristics {
            if char.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: char)
            }
            if char.properties.contains(.read) {
                peripheral.readValue(for: char)
            }
        }
    }

    nonisolated public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        let charUUID = characteristic.uuid
        Task { @MainActor in
            self.parseCharacteristicData(charUUID, data: data)
        }
    }

    // MARK: - GATT Payload Parsing

    private func parseCharacteristicData(_ uuid: CBUUID, data: Data) {
        if uuid == kPowerMeasurementCharUUID {
            parsePowerData(data)
        } else if uuid == kCscMeasurementCharUUID {
            parseCSCData(data)
        } else if uuid == kHrMeasurementCharUUID {
            parseHRData(data)
        } else if uuid == kBatteryLevelCharUUID {
            if let level = data.first {
                self.sensorBatteryLevel = Int(level)
            }
        }
    }

    private func parsePowerData(_ data: Data) {
        guard data.count >= 4 else { return }
        // Bytes 0-1: Flags, Bytes 2-3: Instantaneous Power (sint16)
        let rawPower = Int16(data[2]) | (Int16(data[3]) << 8)
        self.livePower = max(0, Int(rawPower))

        let flags = UInt16(data[0]) | (UInt16(data[1]) << 8)
        // Bit 5 = Crank Revolution Data Present
        if (flags & 0x0020) != 0 && data.count >= 8 {
            var offset = 4
            if (flags & 0x0001) != 0 { offset += 1 }
            if (flags & 0x0004) != 0 { offset += 2 }
            if (flags & 0x0010) != 0 { offset += 6 }

            if data.count >= offset + 4 {
                let crankRev = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
                let crankTime = UInt16(data[offset + 2]) | (UInt16(data[offset + 3]) << 8)
                calculateCadence(crankRev: crankRev, crankTime: crankTime)
            }
        }
    }

    private func parseCSCData(_ data: Data) {
        guard data.count >= 1 else { return }
        let flags = data[0]
        var offset = 1

        let wheelPresent = (flags & 0x01) != 0
        let crankPresent = (flags & 0x02) != 0

        if wheelPresent && data.count >= offset + 6 {
            let wheelRev = UInt32(data[offset]) | (UInt32(data[offset + 1]) << 8) | (UInt32(data[offset + 2]) << 16) | (UInt32(data[offset + 3]) << 24)
            let wheelTime = UInt16(data[offset + 4]) | (UInt16(data[offset + 5]) << 8)
            calculateWheelSpeed(wheelRev: wheelRev, wheelTime: wheelTime)
            offset += 6
        }

        if crankPresent && data.count >= offset + 4 {
            let crankRev = UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8)
            let crankTime = UInt16(data[offset + 2]) | (UInt16(data[offset + 3]) << 8)
            calculateCadence(crankRev: crankRev, crankTime: crankTime)
        }
    }

    private func parseHRData(_ data: Data) {
        guard data.count >= 2 else { return }
        let flags = data[0]
        let is16Bit = (flags & 0x01) != 0
        let hr: Int
        if is16Bit && data.count >= 3 {
            hr = Int(UInt16(data[1]) | (UInt16(data[2]) << 8))
        } else {
            hr = Int(data[1])
        }
        self.liveHeartRate = hr
    }

    private func calculateCadence(crankRev: UInt16, crankTime: UInt16) {
        if let lastRev = lastCrankRevolutions, let lastTime = lastCrankEventTime {
            let dRev = crankRev >= lastRev ? (crankRev - lastRev) : (UInt16.max - lastRev + crankRev + 1)
            let dTime = crankTime >= lastTime ? (crankTime - lastTime) : (UInt16.max - lastTime + crankTime + 1)
            if dTime > 0 && dRev > 0 {
                let timeInSec = Double(dTime) / 1024.0
                let rpm = (Double(dRev) / timeInSec) * 60.0
                if rpm > 10 && rpm < 220 {
                    self.liveCadence = Int(rpm.rounded())
                }
            }
        }
        self.lastCrankRevolutions = crankRev
        self.lastCrankEventTime = crankTime
    }

    private func calculateWheelSpeed(wheelRev: UInt32, wheelTime: UInt16) {
        if let lastRev = lastWheelRevolutions, let lastTime = lastWheelEventTime {
            let dRev = wheelRev >= lastRev ? (wheelRev - lastRev) : (UInt32.max - lastRev + wheelRev + 1)
            let dTime = wheelTime >= lastTime ? (wheelTime - lastTime) : (UInt16.max - lastTime + wheelTime + 1)
            if dTime > 0 && dRev > 0 {
                let timeInSec = Double(dTime) / 1024.0
                let circumferenceMeters = 2.105 // Standard 700x25c wheel
                let metersPerSec = (Double(dRev) * circumferenceMeters) / timeInSec
                let kmh = metersPerSec * 3.6
                if kmh >= 0 && kmh < 120 {
                    self.liveSpeedKmh = kmh
                }
            }
        }
        self.lastWheelRevolutions = wheelRev
        self.lastWheelEventTime = wheelTime
    }
}
