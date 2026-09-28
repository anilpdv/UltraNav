import Foundation

struct SensorServiceDefinition: Equatable, Sendable {
    let sensorTypes: Set<SensorType>
    let serviceIdentifier: String
    let measurementCharacteristicIdentifier: String
    let optionalCharacteristicIdentifiers: Set<String>
}

extension SensorServiceDefinition {
    static let heartRate = SensorServiceDefinition(
        sensorTypes: [.heartRate],
        serviceIdentifier: "180D",
        measurementCharacteristicIdentifier: "2A37",
        optionalCharacteristicIdentifiers: []
    )

    static let cyclingSpeedAndCadence = SensorServiceDefinition(
        sensorTypes: [
            .cyclingSpeed,
            .cyclingCadence,
            .combinedSpeedCadence
        ],
        serviceIdentifier: "1816",
        measurementCharacteristicIdentifier: "2A5B",
        optionalCharacteristicIdentifiers: [
            "2A5C",
            "2A5D"
        ]
    )

    static let cyclingPower = SensorServiceDefinition(
        sensorTypes: [.cyclingPower],
        serviceIdentifier: "1818",
        measurementCharacteristicIdentifier: "2A63",
        optionalCharacteristicIdentifiers: [
            "2A65",
            "2A5D"
        ]
    )

    static let allKnownDefinitions: [SensorServiceDefinition] = [
        .heartRate,
        .cyclingSpeedAndCadence,
        .cyclingPower
    ]
}
