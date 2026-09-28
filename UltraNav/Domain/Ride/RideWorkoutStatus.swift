import Foundation

enum RideWorkoutStatus: Equatable, Sendable {
    case unavailable
    case preparing
    case ready
    case active
    case paused
    case finalizing
    case ended
    case failed
}
