import Foundation

/// Parsed standalone waypoint (<wpt>).
public struct GPXParsedWaypoint: Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let name: String?
    public let description: String?
    public let symbol: String?
    public let elevation: Double?
    public let time: Date?

    public init(
        latitude: Double,
        longitude: Double,
        name: String? = nil,
        description: String? = nil,
        symbol: String? = nil,
        elevation: Double? = nil,
        time: Date? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.name = name
        self.description = description
        self.symbol = symbol
        self.elevation = elevation
        self.time = time
    }
}
