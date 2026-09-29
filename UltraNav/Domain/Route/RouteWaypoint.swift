import Foundation

/// Represents a standalone point of interest / waypoint attached to a route.
public struct RouteWaypoint: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: UUID
    public let coordinate: Coordinate
    public let name: String
    public let description: String?
    public let symbol: String?
    public let elevationMeters: Double?

    public init(
        id: UUID = UUID(),
        coordinate: Coordinate,
        name: String,
        description: String? = nil,
        symbol: String? = nil,
        elevationMeters: Double? = nil
    ) {
        self.id = id
        self.coordinate = coordinate
        self.name = name
        self.description = description
        self.symbol = symbol
        self.elevationMeters = elevationMeters
    }
}
