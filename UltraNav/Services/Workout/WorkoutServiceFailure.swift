import Foundation

enum WorkoutServiceFailure: Error, Equatable, Sendable {
    case healthDataUnavailable
    case authorizationDenied
    case preparationFailed
    case startFailed
    case pauseFailed
    case resumeFailed
    case finishFailed
    case invalidServiceState
    case unexpected
}
