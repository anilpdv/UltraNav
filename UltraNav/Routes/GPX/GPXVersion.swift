import Foundation

/// Supported GPX specification versions.
public enum GPXVersion: String, Equatable, Sendable, Codable {
    case version1_0 = "1.0"
    case version1_1 = "1.1"
}
