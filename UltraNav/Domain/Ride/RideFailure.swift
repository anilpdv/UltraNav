import Foundation

enum RideFailure: Error, Equatable, Sendable {
    case locationPermissionRequired
    case locationPermissionDenied
    case locationUnavailable

    case workoutAuthorizationDenied
    case workoutPreparationFailed
    case workoutStartFailed
    case workoutPauseFailed
    case workoutResumeFailed
    case workoutFinishFailed

    case invalidStateTransition(
        from: RideStateName,
        event: RideEventName
    )

    case unexpected
}
