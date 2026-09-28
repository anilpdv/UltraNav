import Foundation

enum SensorServiceFailure: Error, Equatable, Sendable {
    case bluetoothUnavailable(BluetoothAvailability)
    case scanFailed
    case unknownSensor(SensorIdentifier)
    case connectionFailed(SensorIdentifier)
    case disconnectedUnexpectedly(SensorIdentifier)
    case serviceDiscoveryFailed(SensorIdentifier)
    case requiredServiceMissing(
        sensor: SensorIdentifier,
        serviceIdentifier: String
    )
    case characteristicDiscoveryFailed(SensorIdentifier)
    case requiredCharacteristicMissing(
        sensor: SensorIdentifier,
        characteristicIdentifier: String
    )
    case notificationSetupFailed(
        sensor: SensorIdentifier,
        characteristicIdentifier: String
    )
    case malformedMeasurement(
        sensor: SensorIdentifier,
        characteristicIdentifier: String
    )
    case invalidServiceState
    case unexpected
}
