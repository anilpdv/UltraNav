import Foundation
@testable import UltraNav

enum SensorFactory {
    static func makeDescriptor(
        id: String = "test-sensor-01",
        name: String = "Test Sensor",
        types: Set<SensorType> = [.heartRate],
        isRemembered: Bool = false
    ) -> SensorDescriptor {
        SensorDescriptor(
            id: SensorIdentifier(rawValue: id),
            name: name,
            supportedTypes: types,
            isRemembered: isRemembered
        )
    }

    static func makeHRPacket(
        sensorId: String = "hrm-01",
        bpm: UInt8 = 145,
        receivedAt: Date = Date()
    ) -> SensorMeasurementPacket {
        // Flags: 0 (8-bit HR format), HR: bpm
        let payload = Data([0x00, bpm])
        return SensorMeasurementPacket(
            sensor: SensorIdentifier(rawValue: sensorId),
            serviceIdentifier: "180D",
            characteristicIdentifier: "2A37",
            payload: payload,
            receivedAt: receivedAt
        )
    }

    static func makePowerPacket(
        sensorId: String = "power-01",
        watts: UInt16 = 250,
        receivedAt: Date = Date()
    ) -> SensorMeasurementPacket {
        // Flags: 0, Instantaneous Power: watts (little endian)
        let payload = Data([0x00, 0x00, UInt8(watts & 0xFF), UInt8(watts >> 8)])
        return SensorMeasurementPacket(
            sensor: SensorIdentifier(rawValue: sensorId),
            serviceIdentifier: "1818",
            characteristicIdentifier: "2A63",
            payload: payload,
            receivedAt: receivedAt
        )
    }
}
