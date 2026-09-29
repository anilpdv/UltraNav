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

    /// Computes the great-circle distance between two coordinates in meters.
    func distance(to other: Coordinate) -> Double {
        let earthRadiusMeters = 6_371_000.0
        let lat1 = latitude * .pi / 180.0
        let lat2 = other.latitude * .pi / 180.0
        let deltaLat = (other.latitude - latitude) * .pi / 180.0
        let deltaLon = (other.longitude - longitude) * .pi / 180.0

        let a = sin(deltaLat / 2.0) * sin(deltaLat / 2.0) +
                cos(lat1) * cos(lat2) *
                sin(deltaLon / 2.0) * sin(deltaLon / 2.0)
        let c = 2.0 * atan2(sqrt(a), sqrt(max(0.0, 1.0 - a)))
        return earthRadiusMeters * c
    }

    /// Computes the initial bearing in degrees from this coordinate to another [0, 360).
    func initialBearing(to other: Coordinate) -> Double {
        let lat1 = latitude * .pi / 180.0
        let lat2 = other.latitude * .pi / 180.0
        let deltaLon = (other.longitude - longitude) * .pi / 180.0

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let radians = atan2(y, x)
        let degrees = (radians * 180.0 / .pi).truncatingRemainder(dividingBy: 360.0)
        return degrees >= 0 ? degrees : degrees + 360.0
    }
}
