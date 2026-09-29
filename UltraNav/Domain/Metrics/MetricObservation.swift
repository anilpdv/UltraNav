import Foundation

struct MetricObservation: Equatable, Sendable {
    let source: MetricSource
    let value: MetricValue
    let timestamp: Date

    init(source: MetricSource, value: MetricValue, timestamp: Date) {
        self.source = source
        self.value = value
        self.timestamp = timestamp
    }
}
