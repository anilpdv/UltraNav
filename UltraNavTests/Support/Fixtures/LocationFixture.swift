import Foundation
@testable import UltraNav

/// Standardized location samples and scenarios for deterministic tests.
enum LocationFixture {
    /// Creates a deterministic sample with default accurate cycling parameters.
    static func sample(
        latitude: Double = 24.7136,
        longitude: Double = 46.6753,
        altitudeMeters: Double? = 600.0,
        horizontalAccuracyMeters: Double = 5.0,
        speedMetersPerSecond: Double? = 8.0,
        courseDegrees: Double? = 90.0,
        timestamp: Date = TestDates.rideStart
    ) -> LocationSample {
        LocationSample(
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            altitudeMeters: altitudeMeters,
            horizontalAccuracyMeters: horizontalAccuracyMeters,
            verticalAccuracyMeters: 8.0,
            speedMetersPerSecond: speedMetersPerSecond,
            courseDegrees: courseDegrees,
            timestamp: timestamp
        )
    }

    /// Accurate moving GPS fix.
    static func accurate(
        timestamp: Date = TestDates.rideStart
    ) -> LocationSample {
        sample(horizontalAccuracyMeters: 3.0, speedMetersPerSecond: 10.0, timestamp: timestamp)
    }

    /// Stationary position.
    static func stationary(
        timestamp: Date = TestDates.rideStart
    ) -> LocationSample {
        sample(speedMetersPerSecond: 0.0, timestamp: timestamp)
    }

    /// Low accuracy / degraded GPS.
    static func poorAccuracy(
        timestamp: Date = TestDates.rideStart
    ) -> LocationSample {
        sample(horizontalAccuracyMeters: 85.0, timestamp: timestamp)
    }

    /// Invalid / out-of-order timestamp.
    static func stale(
        timestamp: Date = TestDates.rideStart.addingTimeInterval(-100)
    ) -> LocationSample {
        sample(timestamp: timestamp)
    }
}
