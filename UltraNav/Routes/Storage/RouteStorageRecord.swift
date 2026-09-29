import Foundation

/// Versioned storage container for an individual route file (<route-id>.json).
public struct RouteStorageRecord: Equatable, Hashable, Codable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public let route: Route
    public let summary: RouteSummary

    public init(schemaVersion: Int = currentSchemaVersion, route: Route, summary: RouteSummary? = nil) {
        self.schemaVersion = schemaVersion
        self.route = route
        self.summary = summary ?? RouteSummary(from: route)
    }
}
