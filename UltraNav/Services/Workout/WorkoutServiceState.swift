import Foundation

enum WorkoutServiceState: Equatable, Sendable {
    case idle
    case authorizing
    case preparing
    case prepared
    case ready
    case starting
    case running
    case pausing
    case paused
    case resuming
    case stopping
    case finalizing
    case ending
    case ended
    case failed
}
