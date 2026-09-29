import Foundation

/// Value type representing a single raw geographic location sample.
public struct LocationSample: Equatable, Hashable, Codable, Sendable {
    public let coordinate: Coordinate
    public let altitudeMeters: Double?
    public let horizontalAccuracyMeters: Double
    public let verticalAccuracyMeters: Double?
    public let speedMetersPerSecond: Double?
    public let speedAccuracyMetersPerSecond: Double?
    public let courseDegrees: Double?
    public let courseAccuracyDegrees: Double?
    public let timestamp: Date

    public init(
        coordinate: Coordinate,
        altitudeMeters: Double? = nil,
        horizontalAccuracyMeters: Double = 0,
        verticalAccuracyMeters: Double? = nil,
        speedMetersPerSecond: Double? = nil,
        speedAccuracyMetersPerSecond: Double? = nil,
        courseDegrees: Double? = nil,
        courseAccuracyDegrees: Double? = nil,
        timestamp: Date
    ) {
        self.coordinate = coordinate
        self.altitudeMeters = altitudeMeters
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.speedMetersPerSecond = speedMetersPerSecond
        self.speedAccuracyMetersPerSecond = speedAccuracyMetersPerSecond
        self.courseDegrees = courseDegrees
        self.courseAccuracyDegrees = courseAccuracyDegrees
        self.timestamp = timestamp
    }
}
