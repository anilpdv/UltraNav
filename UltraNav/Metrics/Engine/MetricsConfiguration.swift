import Foundation

struct MetricsConfiguration: Equatable, Sendable {
    let freshness: MetricFreshness
    let sourcePolicy: MetricSourcePolicy
    let validation: MetricValidationPolicy
    let power: PowerMetricsConfiguration
    let laps: LapConfiguration

    static let outdoorCycling = MetricsConfiguration(
        freshness: .standard,
        sourcePolicy: .outdoorCycling,
        validation: .standard,
        power: .standard,
        laps: .standard
    )
}
