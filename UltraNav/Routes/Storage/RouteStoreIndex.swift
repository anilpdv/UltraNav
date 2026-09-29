import Foundation

/// Fast index containing metadata summaries of all persisted routes (index-v1.json).
public struct RouteStoreIndex: Equatable, Hashable, Codable, Sendable {
    public static let currentSchemaVersion = 1

    public let schemaVersion: Int
    public var summaries: [RouteSummary]
    public var lastUpdated: Date

    public init(
        schemaVersion: Int = currentSchemaVersion,
        summaries: [RouteSummary] = [],
        lastUpdated: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.summaries = summaries
        self.lastUpdated = lastUpdated
    }
}
