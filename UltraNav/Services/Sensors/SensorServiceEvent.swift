import Foundation

enum SensorServiceEvent: Equatable, Sendable {
    case availabilityChanged(
        BluetoothAvailability
    )

    case scanStateChanged(
        SensorScanState
    )

    case sensorDiscovered(
        SensorDiscovery
    )

    case connectionStateChanged(
        sensor: SensorIdentifier,
        state: SensorConnectionState
    )

    case sensorReady(
        SensorDescriptor
    )

    case sampleReceived(
        sensor: SensorIdentifier,
        sample: SensorSample
    )

    case failed(
        SensorServiceFailure
    )
}
