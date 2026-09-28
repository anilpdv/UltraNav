import Foundation
@testable import UltraNav

enum LocationSampleFactory {
    static func make(
        latitude: Double = 24.7136,
        longitude: Double = 46.6753,
        altitudeMeters: Double? = 600,
        horizontalAccuracyMeters: Double = 5,
        verticalAccuracyMeters: Double? = 8,
        speedMetersPerSecond: Double? = 7,
        courseDegrees: Double? = 90,
        timestamp: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> LocationSample {
        LocationSample(
            coordinate: Coordinate(
                latitude: latitude,
                longitude: longitude
            ),
            altitudeMeters: altitudeMeters,
            horizontalAccuracyMeters: horizontalAccuracyMeters,
            verticalAccuracyMeters: verticalAccuracyMeters,
            speedMetersPerSecond: speedMetersPerSecond,
            courseDegrees: courseDegrees,
            timestamp: timestamp
        )
    }

    static func makeSample(
        speed: Double? = 7,
        altitude: Double? = 600,
        latitude: Double = 24.7136,
        longitude: Double = 46.6753,
        horizontalAccuracy: Double = 5,
        verticalAccuracy: Double? = 8,
        course: Double? = 90,
        timestamp: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> LocationSample {
        make(
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: altitude,
            horizontalAccuracyMeters: horizontalAccuracy,
            verticalAccuracyMeters: verticalAccuracy,
            speedMetersPerSecond: speed,
            courseDegrees: course,
            timestamp: timestamp
        )
    }

    static func makeSample(
        altitude: Double?,
        speed: Double? = 7,
        latitude: Double = 24.7136,
        longitude: Double = 46.6753,
        horizontalAccuracy: Double = 5,
        verticalAccuracy: Double? = 8,
        course: Double? = 90,
        timestamp: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> LocationSample {
        make(
            latitude: latitude,
            longitude: longitude,
            altitudeMeters: altitude,
            horizontalAccuracyMeters: horizontalAccuracy,
            verticalAccuracyMeters: verticalAccuracy,
            speedMetersPerSecond: speed,
            courseDegrees: course,
            timestamp: timestamp
        )
    }
}
