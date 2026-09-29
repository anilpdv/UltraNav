import Foundation

/// Canonical single point along a normalized route.
public struct RoutePoint: Equatable, Hashable, Codable, Sendable {
    public let coordinate: Coordinate

    /// Elevation in meters, when supplied by the route source.
    public let elevationMeters: Double?

    /// Original timestamp from the route source.
    public let timestamp: Date?

    /// Distance from the beginning of the normalized route, in meters.
    public let cumulativeDistanceMeters: Double

    public init(
        coordinate: Coordinate,
        elevationMeters: Double? = nil,
        timestamp: Date? = nil,
        cumulativeDistanceMeters: Double
    ) {
        self.coordinate = coordinate
        self.elevationMeters = elevationMeters
        self.timestamp = timestamp
        self.cumulativeDistanceMeters = cumulativeDistanceMeters
    }
}
