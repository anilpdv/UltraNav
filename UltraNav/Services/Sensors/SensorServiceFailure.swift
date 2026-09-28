import Foundation

enum SensorServiceFailure: Error, Equatable, Sendable {
    case bluetoothUnavailable
    case bluetoothUnauthorized
    case scanFailed
    case connectionFailed(
        SensorIdentifier
    )
    case discoveryFailed(
        SensorIdentifier
    )
    case notificationSetupFailed(
        SensorIdentifier
    )
    case disconnectedUnexpectedly(
        SensorIdentifier
    )
    case malformedMeasurement(
        sensor: SensorIdentifier,
        type: SensorType
    )
    case unexpected
}
