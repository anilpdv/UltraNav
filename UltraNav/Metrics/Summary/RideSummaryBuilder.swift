import Foundation

struct RideSummaryBuilder: Sendable {
    func build(
        startedAt: Date,
        finishedAt: Date,
        elapsedTimeSeconds: TimeInterval,
        activeTimeSeconds: TimeInterval,
        movingTimeSeconds: TimeInterval,
        distanceMeters: Double,
        averageActiveSpeed: Double?,
        averageMovingSpeed: Double?,
        maxSpeed: Double?,
        averageHeartRate: Double?,
        maxHeartRate: Double?,
        averageCadence: Double?,
        maxCadence: Double?,
        averagePower: Double?,
        maxPower: Double?,
        normalizedPower: Double?,
        intensityFactor: Double?,
        trainingStressScore: Double?,
        activeEnergyKilocalories: Double?,
        laps: [LapRecord],
        dataQuality: RideMetricsDataQuality
    ) -> RideMetricsSummary {
        RideMetricsSummary(
            startedAt: startedAt,
            finishedAt: finishedAt,
            elapsedTimeSeconds: max(0, elapsedTimeSeconds),
            activeTimeSeconds: max(0, activeTimeSeconds),
            movingTimeSeconds: max(0, movingTimeSeconds),
            distanceMeters: max(0, distanceMeters),
            averageActiveSpeedMetersPerSecond: averageActiveSpeed,
            averageMovingSpeedMetersPerSecond: averageMovingSpeed,
            maximumSpeedMetersPerSecond: maxSpeed,
            averageHeartRateBPM: averageHeartRate,
            maximumHeartRateBPM: maxHeartRate,
            averageCadenceRPM: averageCadence,
            maximumCadenceRPM: maxCadence,
            averagePowerWatts: averagePower,
            maximumPowerWatts: maxPower,
            normalizedPowerWatts: normalizedPower,
            intensityFactor: intensityFactor,
            trainingStressScore: trainingStressScore,
            activeEnergyKilocalories: activeEnergyKilocalories,
            laps: laps,
            dataQuality: dataQuality
        )
    }
}
