import Foundation

struct CurrentMetric<T: Equatable & Sendable>: Equatable, Sendable {
    let value: T
    let source: MetricSource
    let timestamp: Date
    let freshness: MetricFreshness

    init(
        value: T,
        source: MetricSource,
        timestamp: Date,
        freshness: MetricFreshness = .fresh
    ) {
        self.value = value
        self.source = source
        self.timestamp = timestamp
        self.freshness = freshness
    }
}
