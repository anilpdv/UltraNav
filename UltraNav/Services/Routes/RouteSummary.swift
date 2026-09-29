import Foundation

/// Lightweight summary of a Route for fast catalog listing and display.
public struct RouteSummary: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: Route.ID
    public let name: String
    public let description: String?
    public let source: RouteSource
    public let totalDistanceMeters: Double
    public let totalAscentMeters: Double?
    public let pointCount: Int
    public let segmentCount: Int
    public let waypointCount: Int
    public let hasElevation: Bool
    public let importedAt: Date
    public let bounds: RouteBounds

    public init(
        id: Route.ID,
        name: String,
        description: String? = nil,
        source: RouteSource = .unknown,
        totalDistanceMeters: Double,
        totalAscentMeters: Double? = nil,
        pointCount: Int,
        segmentCount: Int = 1,
        waypointCount: Int = 0,
        hasElevation: Bool = false,
        importedAt: Date = Date(),
        bounds: RouteBounds = .zero
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.source = source
        self.totalDistanceMeters = totalDistanceMeters
        self.totalAscentMeters = totalAscentMeters
        self.pointCount = pointCount
        self.segmentCount = segmentCount
        self.waypointCount = waypointCount
        self.hasElevation = hasElevation
        self.importedAt = importedAt
        self.bounds = bounds
    }

    /// Convenience initializer mapping directly from a domain Route.
    public init(from route: Route) {
        self.id = route.id
        self.name = route.metadata.name
        self.description = route.metadata.description
        self.source = route.metadata.source
        self.totalDistanceMeters = route.totalDistanceMeters
        self.totalAscentMeters = route.totalAscentMeters
        self.pointCount = route.points.count
        self.segmentCount = route.segments.count
        self.waypointCount = route.waypoints.count
        self.hasElevation = route.points.contains { $0.elevationMeters != nil }
        self.importedAt = route.metadata.importedAt
        self.bounds = route.bounds
    }

    /// Backwards compatibility initializer
    public init(
        id: Route.ID,
        name: String,
        totalDistanceMeters: Double,
        pointCount: Int,
        createdAt: Date?
    ) {
        self.id = id
        self.name = name
        self.description = nil
        self.source = .unknown
        self.totalDistanceMeters = totalDistanceMeters
        self.totalAscentMeters = nil
        self.pointCount = pointCount
        self.segmentCount = 1
        self.waypointCount = 0
        self.hasElevation = false
        self.importedAt = createdAt ?? Date()
        self.bounds = .zero
    }

    public var createdAt: Date? {
        importedAt
    }
}
