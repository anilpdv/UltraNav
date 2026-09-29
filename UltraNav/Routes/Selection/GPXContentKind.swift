import Foundation

/// Identifies the kind of GPX content extracted.
public enum GPXContentKind: String, Equatable, Sendable, Codable {
    case track
    case route
    case mergedTracks
    case waypointsOnly
}
