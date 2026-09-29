import Foundation

struct MetricValidationPolicy: Equatable, Sendable {
    let maximumSpeedMetersPerSecond: Double
    let maximumHeartRateBPM: Double
    let maximumCadenceRPM: Double
    let minimumPowerWatts: Double
    let maximumPowerWatts: Double
    let minimumAltitudeMeters: Double
    let maximumAltitudeMeters: Double

    static let standard = MetricValidationPolicy(
        maximumSpeedMetersPerSecond: 40.0,
        maximumHeartRateBPM: 250.0,
        maximumCadenceRPM: 250.0,
        minimumPowerWatts: -500.0,
        maximumPowerWatts: 3_000.0,
        minimumAltitudeMeters: -500.0,
        maximumAltitudeMeters: 10_000.0
    )
}
