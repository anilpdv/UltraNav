import Foundation

/// Geographic bounding box of a route.
public struct RouteBounds: Equatable, Hashable, Codable, Sendable {
    public let minimumLatitude: Double
    public let maximumLatitude: Double
    public let minimumLongitude: Double
    public let maximumLongitude: Double

    public init(
        minimumLatitude: Double,
        maximumLatitude: Double,
        minimumLongitude: Double,
        maximumLongitude: Double
    ) {
        self.minimumLatitude = minimumLatitude
        self.maximumLatitude = maximumLatitude
        self.minimumLongitude = minimumLongitude
        self.maximumLongitude = maximumLongitude
    }

    public static let zero = RouteBounds(
        minimumLatitude: 0,
        maximumLatitude: 0,
        minimumLongitude: 0,
        maximumLongitude: 0
    )
}
