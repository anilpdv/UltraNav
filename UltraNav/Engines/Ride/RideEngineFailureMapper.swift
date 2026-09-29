import Foundation

struct RideEngineFailureMapper: Sendable {
    func map(_ failure: LocationServiceFailure) -> RideFailure {
        switch failure {
        case .authorizationDenied:
            return .locationPermissionDenied

        case .authorizationRestricted,
             .servicesDisabled,
             .updatesUnavailable,
             .updateFailed,
             .alreadyRunning,
             .unexpected:
            return .locationUnavailable
        }
    }

    func map(_ failure: WorkoutServiceFailure) -> RideFailure {
        switch failure {
        case .authorizationRequired,
             .authorizationFailed:
            return .workoutAuthorizationDenied

        case .preparationFailed,
             .configurationFailed,
             .sessionCreationFailed,
             .builderCreationFailed:
            return .workoutPreparationFailed

        case .startFailed,
             .collectionStartFailed:
            return .workoutStartFailed

        case .pauseFailed:
            return .workoutPauseFailed

        case .resumeFailed:
            return .workoutResumeFailed

        case .collectionEndFailed,
             .workoutSaveFailed,
             .unexpectedSessionEnd:
            return .workoutFinishFailed

        default:
            return .unexpected
        }
    }
}
