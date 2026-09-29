import Foundation

/// High-level lifecycle state of the ClimbEngine.
enum ClimbEngineState: String, Equatable, Sendable, Codable {
    case unloaded
    case analyzing
    case ready
    case activeClimb
    case completedAllClimbs
    case failed
}
