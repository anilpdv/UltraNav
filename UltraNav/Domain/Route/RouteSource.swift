import Foundation

/// Represents the origin source of a route.
public enum RouteSource: Equatable, Hashable, Codable, Sendable {
    case importedGPX(originalFileName: String)
    case bundled(resourceName: String)
    case generated
    case unknown
}
