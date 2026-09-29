import Foundation

/// Classified physical movement state of the rider based on GPS evidence.
public enum MovementState: String, Equatable, Hashable, Codable, Sendable {
    case unknown
    case stationary
    case moving
}
