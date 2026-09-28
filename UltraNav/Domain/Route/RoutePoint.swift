import Foundation

struct RoutePoint: Equatable, Sendable {
    let coordinate: Coordinate

    /// Elevation in meters, when supplied by the route source.
    let elevationMeters: Double?

    /// Original timestamp from the route source.
    let timestamp: Date?

    /// Distance from the beginning of the normalized route, in meters.
    let cumulativeDistanceMeters: Double
}
