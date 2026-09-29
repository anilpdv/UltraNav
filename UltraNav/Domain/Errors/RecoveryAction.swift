import Foundation

enum RecoveryAction: Equatable, Hashable, Sendable {
    case retry
    case retryAfterDelay
    case continueWithoutSensors
    case continueWithoutNavigation
    case continueWithoutClimbData
    case selectAnotherRoute
    case requestLocationPermission
    case requestHealthPermission
    case openSystemSettings
    case reconnectSensor(SensorIdentifier)
    case finishRideWithoutHealthKitSave
    case saveRideLocally
    case resetSubsystem
    case resetRide
    case dismiss
    case contactSupport
}
