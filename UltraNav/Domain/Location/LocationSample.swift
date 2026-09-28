import Foundation

struct LocationSample: Equatable, Sendable {
    let coordinate: Coordinate

    /// Altitude above mean sea level, in meters.
    let altitudeMeters: Double?

    /// Horizontal position accuracy, in meters.
    let horizontalAccuracyMeters: Double

    /// Vertical position accuracy, in meters.
    let verticalAccuracyMeters: Double?

    /// System-reported speed, in meters per second.
    let speedMetersPerSecond: Double?

    /// Direction of travel in degrees from true north.
    let courseDegrees: Double?

    let timestamp: Date

    init(
        coordinate: Coordinate,
        altitudeMeters: Double? = nil,
        horizontalAccuracyMeters: Double = 0,
        verticalAccuracyMeters: Double? = nil,
        speedMetersPerSecond: Double? = nil,
        courseDegrees: Double? = nil,
        timestamp: Date
    ) {
        self.coordinate = coordinate
        self.altitudeMeters = altitudeMeters
        self.horizontalAccuracyMeters = horizontalAccuracyMeters
        self.verticalAccuracyMeters = verticalAccuracyMeters
        self.speedMetersPerSecond = speedMetersPerSecond
        self.courseDegrees = courseDegrees
        self.timestamp = timestamp
    }
}
