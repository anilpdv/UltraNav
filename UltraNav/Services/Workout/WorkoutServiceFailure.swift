import Foundation

enum WorkoutServiceFailure: Error, Equatable, Sendable {
    case healthDataUnavailable
    case authorizationRequired
    case authorizationDenied
    case authorizationFailed

    case configurationFailed
    case sessionCreationFailed
    case builderCreationFailed

    case preparationFailed
    case startFailed
    case pauseFailed
    case resumeFailed

    case collectionStartFailed
    case collectionEndFailed
    case workoutSaveFailed
    case finishFailed

    case unexpectedSessionEnd
    case competingWorkoutDetected
    case invalidServiceState
    case unexpected
}
