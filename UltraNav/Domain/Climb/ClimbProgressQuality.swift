import Foundation

/// Confidence/quality rating for calculated climb progress.
enum ClimbProgressQuality: String, Equatable, Sendable, Codable {
    case reliable
    case uncertain
    case unavailable
}
