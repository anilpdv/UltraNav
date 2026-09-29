import Foundation

struct PowerMetricsConfiguration: Equatable, Sendable {
    let smoothing: PowerSmoothingConfiguration
    let normalizedPowerWindowSeconds: TimeInterval
    let normalizedPowerMinimumDurationSeconds: TimeInterval
    let includeZeroPower: Bool
    let functionalThresholdPowerWatts: Double?

    static let standard = PowerMetricsConfiguration(
        smoothing: .standard,
        normalizedPowerWindowSeconds: 30.0,
        normalizedPowerMinimumDurationSeconds: 30.0,
        includeZeroPower: true,
        functionalThresholdPowerWatts: nil
    )
}

struct PowerMetricsSnapshot: Equatable, Sendable {
    let currentWatts: Double?
    let threeSecondWatts: Double?
    let tenSecondWatts: Double?
    let thirtySecondWatts: Double?
    let averageWatts: Double?
    let maximumWatts: Double?
    let normalizedPowerWatts: Double?
    let intensityFactor: Double?
    let trainingStressScore: Double?
    let source: MetricSource?
    let availability: MetricAvailability

    static let empty = PowerMetricsSnapshot(
        currentWatts: nil,
        threeSecondWatts: nil,
        tenSecondWatts: nil,
        thirtySecondWatts: nil,
        averageWatts: nil,
        maximumWatts: nil,
        normalizedPowerWatts: nil,
        intensityFactor: nil,
        trainingStressScore: nil,
        source: nil,
        availability: .unavailable
    )
}
