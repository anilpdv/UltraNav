import Foundation

struct RideMetricsDataQuality: Equatable, Sendable {
    let speedCoverageRatio: Double
    let heartRateCoverageRatio: Double
    let cadenceCoverageRatio: Double
    let powerCoverageRatio: Double
    let gpsDistanceAvailable: Bool
    let wheelDistanceAvailable: Bool
    let sourceTransitionCount: Int
    let rejectedObservationCount: Int
}

struct RideMetricsSummary: Equatable, Sendable {
    let startedAt: Date
    let finishedAt: Date
    let elapsedTimeSeconds: TimeInterval
    let activeTimeSeconds: TimeInterval
    let movingTimeSeconds: TimeInterval
    let distanceMeters: Double
    let averageActiveSpeedMetersPerSecond: Double?
    let averageMovingSpeedMetersPerSecond: Double?
    let maximumSpeedMetersPerSecond: Double?
    let averageHeartRateBPM: Double?
    let maximumHeartRateBPM: Double?
    let averageCadenceRPM: Double?
    let maximumCadenceRPM: Double?
    let averagePowerWatts: Double?
    let maximumPowerWatts: Double?
    let normalizedPowerWatts: Double?
    let intensityFactor: Double?
    let trainingStressScore: Double?
    let activeEnergyKilocalories: Double?
    let laps: [LapRecord]
    let dataQuality: RideMetricsDataQuality
}
