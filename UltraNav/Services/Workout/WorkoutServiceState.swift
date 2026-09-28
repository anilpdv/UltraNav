import Foundation

enum WorkoutServiceState: Equatable, Sendable {
    case idle
    case preparing
    case ready
    case starting
    case running
    case pausing
    case paused
    case resuming
    case ending
    case ended
    case failed
}
