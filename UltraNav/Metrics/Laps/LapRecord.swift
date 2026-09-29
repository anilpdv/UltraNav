import Foundation

struct LapMetricsSummary: Equatable, Sendable {
    let elapsedTimeSeconds: TimeInterval
    let activeTimeSeconds: TimeInterval
    let movingTimeSeconds: TimeInterval
    let distanceMeters: Double
    let averageSpeedMetersPerSecond: Double?
    let averageHeartRateBPM: Double?
    let maximumHeartRateBPM: Double?
    let averageCadenceRPM: Double?
    let averagePowerWatts: Double?
    let maximumPowerWatts: Double?
    let normalizedPowerWatts: Double?
}

struct LapRecord: Identifiable, Equatable, Sendable {
    struct ID: RawRepresentable, Hashable, Sendable {
        let rawValue: Int
    }

    let id: ID
    let number: Int
    let trigger: LapTrigger
    let startedAt: Date
    let endedAt: Date
    let startDistanceMeters: Double
    let endDistanceMeters: Double
    let summary: LapMetricsSummary
}

struct LapState: Equatable, Sendable {
    let currentLapNumber: Int
    let currentLapStartedAt: Date
    let currentLapStartDistanceMeters: Double
    let completedLaps: [LapRecord]
}
