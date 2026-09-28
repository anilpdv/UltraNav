import CoreBluetooth
import Foundation

struct CoreBluetoothMapper: Sendable {
    static func mapAvailability(from state: CBManagerState) -> BluetoothAvailability {
        switch state {
        case .unknown:
            return .unknown
        case .resetting:
            return .resetting
        case .unsupported:
            return .unsupported
        case .unauthorized:
            return .unauthorized
        case .poweredOff:
            return .poweredOff
        case .poweredOn:
            return .poweredOn
        @unknown default:
            return .unknown
        }
    }

    static func serviceUUIDs(for sensorTypes: Set<SensorType>) -> [CBUUID] {
        var uuids: Set<CBUUID> = []
        for type in sensorTypes {
            switch type {
            case .heartRate:
                uuids.insert(CoreBluetoothServiceUUID.heartRate)
            case .cyclingPower:
                uuids.insert(CoreBluetoothServiceUUID.cyclingPower)
            case .cyclingSpeed, .cyclingCadence, .combinedSpeedCadence:
                uuids.insert(CoreBluetoothServiceUUID.cyclingSpeedAndCadence)
            }
        }
        return Array(uuids).sorted { $0.uuidString < $1.uuidString }
    }

    static func sensorTypes(for serviceUUIDs: [CBUUID]) -> Set<SensorType> {
        var types: Set<SensorType> = []
        for uuid in serviceUUIDs {
            let normalized = uuid.uuidString.uppercased()
            if normalized == "180D" {
                types.insert(.heartRate)
            } else if normalized == "1818" {
                types.insert(.cyclingPower)
            } else if normalized == "1816" {
                types.insert(.cyclingSpeed)
                types.insert(.cyclingCadence)
                types.insert(.combinedSpeedCadence)
            }
        }
        return types
    }

    static func characteristicUUIDs(for serviceUUID: CBUUID) -> [CBUUID] {
        let normalized = serviceUUID.uuidString.uppercased()
        if normalized == "180D" {
            return [CoreBluetoothCharacteristicUUID.heartRateMeasurement]
        } else if normalized == "1818" {
            return [
                CoreBluetoothCharacteristicUUID.cyclingPowerMeasurement,
                CoreBluetoothCharacteristicUUID.cyclingPowerFeature,
                CoreBluetoothCharacteristicUUID.sensorLocation
            ]
        } else if normalized == "1816" {
            return [
                CoreBluetoothCharacteristicUUID.cscMeasurement,
                CoreBluetoothCharacteristicUUID.cscFeature,
                CoreBluetoothCharacteristicUUID.sensorLocation
            ]
        } else if normalized == "180F" {
            return [CoreBluetoothCharacteristicUUID.batteryLevel]
        }
        return []
    }

    static func isSupportedService(_ uuid: CBUUID) -> Bool {
        let normalized = uuid.uuidString.uppercased()
        return normalized == "180D" || normalized == "1816" || normalized == "1818" || normalized == "180F"
    }

    static func isMeasurementCharacteristic(_ uuid: CBUUID) -> Bool {
        let normalized = uuid.uuidString.uppercased()
        return normalized == "2A37" || normalized == "2A5B" || normalized == "2A63"
    }

    static func shouldReadOnce(_ uuid: CBUUID) -> Bool {
        let normalized = uuid.uuidString.uppercased()
        return normalized == "2A5C" || normalized == "2A65" || normalized == "2A5D" || normalized == "2A19"
    }

    static func normalizeRSSI(_ rssi: NSNumber) -> Int? {
        let val = rssi.intValue
        guard val != 127 else { return nil }
        return val
    }
}

extension BluetoothAvailability {
    init(managerState: CBManagerState) {
        self = CoreBluetoothMapper.mapAvailability(from: managerState)
    }
}
