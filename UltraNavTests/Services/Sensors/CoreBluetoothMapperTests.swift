import XCTest
import CoreBluetooth
@testable import UltraNav

final class CoreBluetoothMapperTests: XCTestCase {
    func testManagerStateMapping() {
        XCTAssertEqual(CoreBluetoothMapper.mapAvailability(from: .unknown), .unknown)
        XCTAssertEqual(CoreBluetoothMapper.mapAvailability(from: .resetting), .resetting)
        XCTAssertEqual(CoreBluetoothMapper.mapAvailability(from: .unsupported), .unsupported)
        XCTAssertEqual(CoreBluetoothMapper.mapAvailability(from: .unauthorized), .unauthorized)
        XCTAssertEqual(CoreBluetoothMapper.mapAvailability(from: .poweredOff), .poweredOff)
        XCTAssertEqual(CoreBluetoothMapper.mapAvailability(from: .poweredOn), .poweredOn)
    }

    func testServiceUUIDsForSensorTypes() {
        let hrUUIDs = CoreBluetoothMapper.serviceUUIDs(for: [.heartRate])
        XCTAssertEqual(hrUUIDs, [CoreBluetoothServiceUUID.heartRate])

        let powerUUIDs = CoreBluetoothMapper.serviceUUIDs(for: [.cyclingPower])
        XCTAssertEqual(powerUUIDs, [CoreBluetoothServiceUUID.cyclingPower])

        let cscUUIDs = CoreBluetoothMapper.serviceUUIDs(for: [.cyclingCadence, .cyclingSpeed])
        XCTAssertEqual(cscUUIDs, [CoreBluetoothServiceUUID.cyclingSpeedAndCadence])

        let combined = CoreBluetoothMapper.serviceUUIDs(for: [.heartRate, .cyclingPower, .combinedSpeedCadence])
        XCTAssertEqual(combined.count, 3)
    }

    func testSensorTypesForServiceUUIDs() {
        let hrTypes = CoreBluetoothMapper.sensorTypes(for: [CoreBluetoothServiceUUID.heartRate])
        XCTAssertEqual(hrTypes, [.heartRate])

        let powerTypes = CoreBluetoothMapper.sensorTypes(for: [CoreBluetoothServiceUUID.cyclingPower])
        XCTAssertEqual(powerTypes, [.cyclingPower])

        let cscTypes = CoreBluetoothMapper.sensorTypes(for: [CoreBluetoothServiceUUID.cyclingSpeedAndCadence])
        XCTAssertTrue(cscTypes.contains(.cyclingSpeed))
        XCTAssertTrue(cscTypes.contains(.cyclingCadence))
    }

    func testCharacteristicUUIDs() {
        let hrChars = CoreBluetoothMapper.characteristicUUIDs(for: CoreBluetoothServiceUUID.heartRate)
        XCTAssertEqual(hrChars, [CoreBluetoothCharacteristicUUID.heartRateMeasurement])

        let powerChars = CoreBluetoothMapper.characteristicUUIDs(for: CoreBluetoothServiceUUID.cyclingPower)
        XCTAssertTrue(powerChars.contains(CoreBluetoothCharacteristicUUID.cyclingPowerMeasurement))
    }

    func testRSSINormalization() {
        XCTAssertEqual(CoreBluetoothMapper.normalizeRSSI(NSNumber(value: -65)), -65)
        XCTAssertEqual(CoreBluetoothMapper.normalizeRSSI(NSNumber(value: 0)), 0)
        XCTAssertNil(CoreBluetoothMapper.normalizeRSSI(NSNumber(value: 127)))
    }
}
