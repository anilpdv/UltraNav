import Foundation

/// Report detailing the output and diagnostics of the route normalization pipeline.
public struct RouteNormalizationReport: Equatable, Sendable {
    public let route: Route
    public let version: RouteNormalizationVersion
    public let originalPointCount: Int
    public let normalizedPointCount: Int
    public let prunedDuplicateCount: Int
    public let segmentCount: Int
    public let waypointCount: Int
    public let totalDistanceMeters: Double
    public let crossesAntimeridian: Bool
    public let warnings: [RouteNormalizationWarning]

    public init(
        route: Route,
        version: RouteNormalizationVersion = .version2,
        originalPointCount: Int,
        normalizedPointCount: Int,
        prunedDuplicateCount: Int,
        segmentCount: Int,
        waypointCount: Int,
        totalDistanceMeters: Double,
        crossesAntimeridian: Bool = false,
        warnings: [RouteNormalizationWarning] = []
    ) {
        self.route = route
        self.version = version
        self.originalPointCount = originalPointCount
        self.normalizedPointCount = normalizedPointCount
        self.prunedDuplicateCount = prunedDuplicateCount
        self.segmentCount = segmentCount
        self.waypointCount = waypointCount
        self.totalDistanceMeters = totalDistanceMeters
        self.crossesAntimeridian = crossesAntimeridian
        self.warnings = warnings
    }
}
