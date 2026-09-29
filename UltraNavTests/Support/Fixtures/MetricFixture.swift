import Foundation
@testable import UltraNav

/// Standardized metric value fixtures and snapshots.
enum MetricFixture {
    static func speedMetric(
        value: Double = 8.5,
        source: MetricSource = .coreLocation,
        timestamp: Date = TestDates.rideStart,
        freshness: MetricFreshness = .fresh
    ) -> CurrentMetric<Double> {
        CurrentMetric(value: value, source: source, timestamp: timestamp, freshness: freshness)
    }

    static func heartRateMetric(
        value: Int = 150,
        source: MetricSource = .bluetooth(sensorID: TestIDs.heartRateSensor),
        timestamp: Date = TestDates.rideStart,
        freshness: MetricFreshness = .fresh
    ) -> CurrentMetric<Int> {
        CurrentMetric(value: value, source: source, timestamp: timestamp, freshness: freshness)
    }

    static func powerMetric(
        value: Int = 260,
        source: MetricSource = .bluetooth(sensorID: TestIDs.powerSensor),
        timestamp: Date = TestDates.rideStart,
        freshness: MetricFreshness = .fresh
    ) -> CurrentMetric<Int> {
        CurrentMetric(value: value, source: source, timestamp: timestamp, freshness: freshness)
    }

    static func cadenceMetric(
        value: Double = 92.0,
        source: MetricSource = .bluetooth(sensorID: TestIDs.speedCadenceSensor),
        timestamp: Date = TestDates.rideStart,
        freshness: MetricFreshness = .fresh
    ) -> CurrentMetric<Double> {
        CurrentMetric(value: value, source: source, timestamp: timestamp, freshness: freshness)
    }

    static func snapshot(
        speed: CurrentMetric<Double>? = speedMetric(),
        heartRate: CurrentMetric<Int>? = heartRateMetric(),
        power: CurrentMetric<Int>? = powerMetric(),
        cadence: CurrentMetric<Double>? = cadenceMetric(),
        timestamp: Date = TestDates.rideStart
    ) -> MetricsSnapshot {
        MetricsSnapshot(
            speed: speed,
            heartRate: heartRate,
            cadence: cadence,
            power: power,
            distance: nil,
            altitude: nil,
            energy: nil,
            averageSpeedMetersPerSecond: speed?.value,
            maxSpeedMetersPerSecond: speed?.value,
            averageHeartRateBeatsPerMinute: heartRate?.value,
            maxHeartRateBeatsPerMinute: heartRate?.value,
            averageCadenceRevolutionsPerMinute: cadence?.value,
            averagePowerWatts: power?.value,
            maxPowerWatts: power?.value,
            normalizedPowerWatts: power?.value,
            totalKilocalories: 250.0,
            availability: .empty,
            timestamp: timestamp
        )
    }

    static func emptySnapshot() -> MetricsSnapshot {
        .empty
    }
}
