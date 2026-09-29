import Foundation

protocol FailurePresenting: Sendable {
    func map(record: FailureRecord) -> FailureViewState
}

struct RecoveryActionPresenter: Sendable {
    static func title(for action: RecoveryAction) -> String {
        switch action {
        case .retry:
            return "Retry"
        case .retryAfterDelay:
            return "Retry Soon"
        case .continueWithoutSensors:
            return "Continue Without Sensors"
        case .continueWithoutNavigation:
            return "Continue Without Route"
        case .continueWithoutClimbData:
            return "Continue Without Climbs"
        case .selectAnotherRoute:
            return "Select Route"
        case .requestLocationPermission:
            return "Allow Location"
        case .requestHealthPermission:
            return "Allow Health Access"
        case .openSystemSettings:
            return "Open Settings"
        case .reconnectSensor:
            return "Reconnect"
        case .finishRideWithoutHealthKitSave:
            return "Finish Without Saving"
        case .saveRideLocally:
            return "Save Locally"
        case .resetSubsystem:
            return "Reset"
        case .resetRide:
            return "Reset Ride"
        case .dismiss:
            return "Dismiss"
        case .contactSupport:
            return "Support"
        }
    }

    static func viewState(for action: RecoveryAction, isDestructive: Bool = false) -> RecoveryActionViewState {
        RecoveryActionViewState(title: title(for: action), action: action, isDestructive: isDestructive)
    }
}

struct FailurePresentationMapper: FailurePresenting {
    func map(record: FailureRecord) -> FailureViewState {
        let (title, message) = userFacingStrings(for: record)

        let primaryAction = record.suggestedActions.first.map {
            RecoveryActionPresenter.viewState(for: $0, isDestructive: isDestructive($0))
        }

        let secondaryAction: RecoveryActionViewState?
        if record.suggestedActions.count > 1 {
            let second = record.suggestedActions[1]
            secondaryAction = RecoveryActionPresenter.viewState(for: second, isDestructive: isDestructive(second))
        } else {
            secondaryAction = nil
        }

        return FailureViewState(
            title: title,
            message: message,
            severity: record.severity,
            isDismissable: record.severity < .critical,
            primaryAction: primaryAction,
            secondaryAction: secondaryAction
        )
    }

    private func isDestructive(_ action: RecoveryAction) -> Bool {
        switch action {
        case .resetRide, .finishRideWithoutHealthKitSave:
            return true
        default:
            return false
        }
    }

    private func userFacingStrings(for record: FailureRecord) -> (title: String, message: String) {
        switch record.failureID {
        case .locationPermissionDenied:
            return ("Location Required", "UltraNav needs location access to track outdoor rides and provide turn guidance.")
        case .locationServiceDisabled:
            return ("Location Disabled", "Location services are turned off on this Apple Watch.")
        case .locationTemporarilyUnknown, .locationUpdateFailed:
            return ("GPS Signal Lost", "Searching for GPS signal. Ride recording continues.")
        case .workoutAuthorizationDenied:
            return ("Health Access Required", "UltraNav needs HealthKit access to record your workout and metrics.")
        case .workoutStartFailed:
            return ("Workout Failed", "Unable to start the Apple Watch workout session.")
        case .workoutPreparationFailed:
            return ("Workout Error", "Unable to prepare the workout session.")
        case .workoutSessionTerminated:
            return ("Workout Ended", "The workout session was ended by another application or system.")
        case .workoutSaveFailed:
            return ("Save Failed", "Unable to save workout to Apple Health. Ride data is saved locally.")
        case .bluetoothUnavailable:
            return ("Bluetooth Off", "Turn on Bluetooth in Settings to connect cycling sensors.")
        case .sensorDisconnected:
            return ("Sensor Disconnected", "A connected cycling sensor lost connection.")
        case .sensorConnectionFailed:
            return ("Connection Failed", "Unable to connect to the requested sensor.")
        case .navigationRouteMissing:
            return ("Route Missing", "The selected navigation route could not be found.")
        case .routeFileNotFound:
            return ("Route Not Found", "The requested GPX file is missing from storage.")
        case .routeMalformedGPX:
            return ("Invalid Route", "The GPX file could not be parsed.")
        case .routeValidationFailed:
            return ("Invalid Route", "The route file format or coordinates are invalid.")
        case .climbAnalysisFailed:
            return ("Climbs Unavailable", "Unable to analyze elevation profile for climbs.")
        default:
            return ("Notice", "An unexpected issue occurred. Ride recording continues.")
        }
    }
}
