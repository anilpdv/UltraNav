import Foundation

struct RideFailureMapper: FailureClassifying {
    typealias Failure = RideFailure

    func classify(failure: RideFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .locationPermissionRequired, .locationPermissionDenied:
            let isDuringActiveRide = context.rideState == .active
            return FailureClassification(
                id: .locationPermissionDenied,
                severity: isDuringActiveRide ? .critical : .high,
                impact: isDuringActiveRide ? [.degradesActiveRide, .requiresUserAttention] : [.blocksRidePreparation, .requiresUserAttention],
                recoverability: .userActionRequired,
                suggestedActions: [.openSystemSettings, .requestLocationPermission],
                diagnosticMessage: "Location authorization required/denied"
            )

        case .locationUnavailable:
            let isDuringActiveRide = context.rideState == .active
            return FailureClassification(
                id: .locationUpdateFailed,
                severity: isDuringActiveRide ? .warning : .high,
                impact: isDuringActiveRide ? .degradesActiveRide : .blocksRidePreparation,
                recoverability: isDuringActiveRide ? .recoverableWithDegradation : .retryable,
                suggestedActions: isDuringActiveRide ? [.dismiss] : [.retry],
                diagnosticMessage: "Location updates unavailable"
            )

        case .workoutAuthorizationDenied:
            return FailureClassification(
                id: .workoutAuthorizationDenied,
                severity: .high,
                impact: [.blocksRidePreparation, .blocksRideStart, .requiresUserAttention],
                recoverability: .userActionRequired,
                suggestedActions: [.openSystemSettings, .requestHealthPermission],
                diagnosticMessage: "HealthKit authorization denied"
            )

        case .workoutPreparationFailed:
            return FailureClassification(
                id: .workoutPreparationFailed,
                severity: .high,
                impact: [.blocksRidePreparation, .blocksRideStart],
                recoverability: .retryable,
                suggestedActions: [.retry, .resetRide],
                diagnosticMessage: "HealthKit workout preparation failed"
            )

        case .workoutStartFailed:
            return FailureClassification(
                id: .workoutStartFailed,
                severity: .critical,
                impact: [.blocksRideStart, .threatensRidePersistence],
                recoverability: .retryable,
                suggestedActions: [.retry, .resetRide],
                diagnosticMessage: "HealthKit workout start failed"
            )

        case .workoutPauseFailed:
            return FailureClassification(
                id: .workoutPauseFailed,
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "HealthKit workout pause failed"
            )

        case .workoutResumeFailed:
            return FailureClassification(
                id: .workoutResumeFailed,
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .retryable,
                suggestedActions: [.retry, .dismiss],
                diagnosticMessage: "HealthKit workout resume failed"
            )

        case .workoutFinishFailed:
            return FailureClassification(
                id: .workoutFinishFailed,
                severity: .high,
                impact: [.threatensRidePersistence, .requiresUserAttention],
                recoverability: .retryable,
                suggestedActions: [.retry, .saveRideLocally, .finishRideWithoutHealthKitSave],
                diagnosticMessage: "HealthKit workout finish failed"
            )

        case .invalidStateTransition(let from, let event):
            return FailureClassification(
                id: FailureID(rawValue: "RIDE-STATE-001"),
                severity: .informational,
                impact: .none,
                recoverability: .notRecoverableForCurrentOperation,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Invalid state transition from \(from) on \(event)"
            )

        case .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "RIDE-UNEXPECTED-001"),
                severity: .high,
                impact: .degradesActiveRide,
                recoverability: .retryable,
                suggestedActions: [.resetRide, .dismiss],
                diagnosticMessage: "Unexpected ride engine failure"
            )
        }
    }
}
