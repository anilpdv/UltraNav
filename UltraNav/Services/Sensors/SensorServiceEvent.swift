import Foundation

enum SensorServiceEvent: Equatable, Sendable {
    case serviceAvailabilityChanged(
        isAvailable: Bool
    )

    case scanStarted

    case sensorDiscovered(
        descriptor: SensorDescriptor,
        signalStrength: Int?
    )

    case scanStopped

    case connectionStateChanged(
        sensor: SensorIdentifier,
        state: SensorConnectionState
    )

    case sampleReceived(
        sensor: SensorIdentifier,
        sample: SensorSample
    )

    case failed(
        SensorServiceFailure
    )
}
