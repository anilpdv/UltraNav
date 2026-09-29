import Foundation

/// V2 representation of stored route record with normalization version and fingerprints.
public struct RouteStorageRecordV2: Equatable, Hashable, Codable, Sendable {
    public static let schemaVersion = 2

    public let schemaVersion: Int
    public let normalizationVersion: RouteNormalizationVersion
    public let route: Route
    public let summary: RouteSummary
    public let fingerprints: RouteFingerprints?
    public let storedAt: Date

    public init(
        schemaVersion: Int = schemaVersion,
        normalizationVersion: RouteNormalizationVersion = .version2,
        route: Route,
        summary: RouteSummary? = nil,
        fingerprints: RouteFingerprints? = nil,
        storedAt: Date = Date()
    ) {
        self.schemaVersion = schemaVersion
        self.normalizationVersion = normalizationVersion
        self.route = route
        self.summary = summary ?? RouteSummary(from: route)
        self.fingerprints = fingerprints
        self.storedAt = storedAt
    }
}
