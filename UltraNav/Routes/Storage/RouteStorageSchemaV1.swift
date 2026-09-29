import Foundation

/// V1 representation of stored route record.
public struct RouteStorageRecordV1: Codable, Sendable {
    public let schemaVersion: Int
    public let route: Route
    public let summary: RouteSummary

    public init(schemaVersion: Int = 1, route: Route, summary: RouteSummary) {
        self.schemaVersion = schemaVersion
        self.route = route
        self.summary = summary
    }
}
