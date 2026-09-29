import Foundation

/// Confidence classification of a route match.
public enum RouteMatchingConfidence: String, Codable, Sendable {
    case high
    case medium
    case low
    case ambiguous
}
