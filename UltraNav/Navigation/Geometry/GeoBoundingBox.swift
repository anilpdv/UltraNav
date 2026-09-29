import Foundation

/// Represents an axis-aligned geographical bounding box.
public struct GeoBoundingBox: Equatable, Sendable {
    public let minLatitude: Double
    public let maxLatitude: Double
    public let minLongitude: Double
    public let maxLongitude: Double

    public init(
        minLatitude: Double,
        maxLatitude: Double,
        minLongitude: Double,
        maxLongitude: Double
    ) {
        self.minLatitude = minLatitude
        self.maxLatitude = maxLatitude
        self.minLongitude = minLongitude
        self.maxLongitude = maxLongitude
    }

    public init(coordinates: [Coordinate]) {
        guard let first = coordinates.first else {
            self.minLatitude = 0
            self.maxLatitude = 0
            self.minLongitude = 0
            self.maxLongitude = 0
            return
        }

        var minLat = first.latitude
        var maxLat = first.latitude
        var minLon = first.longitude
        var maxLon = first.longitude

        for coord in coordinates.dropFirst() {
            if coord.latitude < minLat { minLat = coord.latitude }
            if coord.latitude > maxLat { maxLat = coord.latitude }
            if coord.longitude < minLon { minLon = coord.longitude }
            if coord.longitude > maxLon { maxLon = coord.longitude }
        }

        self.minLatitude = minLat
        self.maxLatitude = maxLat
        self.minLongitude = minLon
        self.maxLongitude = maxLon
    }

    /// Checks if a coordinate is within this bounding box (with optional buffer in degrees).
    public func contains(_ coordinate: Coordinate, bufferDegrees: Double = 0.0) -> Bool {
        coordinate.latitude >= (minLatitude - bufferDegrees) &&
        coordinate.latitude <= (maxLatitude + bufferDegrees) &&
        coordinate.longitude >= (minLongitude - bufferDegrees) &&
        coordinate.longitude <= (maxLongitude + bufferDegrees)
    }

    /// Returns a new bounding box expanded by a buffer in meters (converted approximately to degrees).
    public func expanded(byMeters meters: Double) -> GeoBoundingBox {
        // ~111,000 meters per degree latitude
        let latBuffer = meters / 111_000.0
        let avgLat = (minLatitude + maxLatitude) / 2.0
        let cosLat = cos(avgLat * .pi / 180.0)
        let lonBuffer = meters / (111_000.0 * max(0.1, abs(cosLat)))

        return GeoBoundingBox(
            minLatitude: minLatitude - latBuffer,
            maxLatitude: maxLatitude + latBuffer,
            minLongitude: minLongitude - lonBuffer,
            maxLongitude: maxLongitude + lonBuffer
        )
    }
}
