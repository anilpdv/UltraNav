import Foundation

enum RideState: Equatable, Sendable {
    case idle
    case preparing
    case ready
    case active
    case paused
    case finishing
    case completed
    case failed(RideFailure)
}
