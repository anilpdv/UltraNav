import Foundation

/// Version of the route normalization and geometric identity specification.
public enum RouteNormalizationVersion: String, Hashable, Codable, Equatable, Sendable {
    case version1 = "route-normalization-v1"
    case version2 = "route-normalization-v2"
}
