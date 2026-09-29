import Foundation

public struct Coordinate: Equatable, Hashable, Codable, Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public extension Coordinate {
    var isGeographicallyValid: Bool {
        latitude.isFinite &&
        longitude.isFinite &&
        (-90.0...90.0).contains(latitude) &&
        (-180.0...180.0).contains(longitude)
    }
}
