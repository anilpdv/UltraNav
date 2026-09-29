import Foundation

/// Progress status of an individual climb relative to the rider's course position.
enum ClimbStatus: String, Equatable, Sendable, Codable {
    case upcoming
    case approaching
    case active
    case completed
    case skipped
}
