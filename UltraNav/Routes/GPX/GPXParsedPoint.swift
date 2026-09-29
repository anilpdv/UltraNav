import Foundation

/// Raw parsed point from a GPX document (<trkpt>, <rtept>, <wpt>).
public struct GPXParsedPoint: Equatable, Hashable, Sendable {
    public let latitude: Double
    public let longitude: Double
    public let elevation: Double?
    public let time: Date?

    public init(
        latitude: Double,
        longitude: Double,
        elevation: Double? = nil,
        time: Date? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
        self.time = time
    }
}
