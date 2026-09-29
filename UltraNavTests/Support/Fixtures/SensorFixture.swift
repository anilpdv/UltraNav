import Foundation
@testable import UltraNav

/// Standardized sensor sample fixtures for heart rate, power, cadence, and speed.
enum SensorFixture {
    static func heartRateSample(
        bpm: Int = 145,
        timestamp: Date = TestDates.rideStart
    ) -> SensorSample {
        .heartRate(beatsPerMinute: bpm, timestamp: timestamp)
    }

    static func powerSample(
        watts: Int = 250,
        timestamp: Date = TestDates.rideStart
    ) -> SensorSample {
        .power(watts: watts, timestamp: timestamp)
    }

    static func cadenceSample(
        rpm: Double = 90.0,
        timestamp: Date = TestDates.rideStart
    ) -> SensorSample {
        .cadence(revolutionsPerMinute: rpm, timestamp: timestamp)
    }

    static func speedSample(
        metersPerSecond: Double = 8.5,
        timestamp: Date = TestDates.rideStart
    ) -> SensorSample {
        .speed(metersPerSecond: metersPerSecond, timestamp: timestamp)
    }
}
