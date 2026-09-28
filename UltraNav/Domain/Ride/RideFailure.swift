import Foundation

enum RideFailure: Error, Equatable, Sendable {
    case locationPermissionDenied
    case locationUnavailable

    case workoutAuthorizationDenied
    case workoutPreparationFailed
    case workoutStartFailed
    case workoutPauseFailed
    case workoutResumeFailed
    case workoutFinishFailed

    case invalidStateTransition
    case unexpected
}
