import Foundation

struct MetricObservation: Equatable, Sendable {
    let kind: MetricKind
    let value: MetricValue
    let source: MetricSource
    let measuredAt: Date
    let receivedAt: Date
    let quality: MetricQuality
    let sequence: UInt64?

    init(
        kind: MetricKind,
        value: MetricValue,
        source: MetricSource,
        measuredAt: Date,
        receivedAt: Date = Date(),
        quality: MetricQuality = .valid,
        sequence: UInt64? = nil
    ) {
        self.kind = kind
        self.value = value
        self.source = source
        self.measuredAt = measuredAt
        self.receivedAt = receivedAt
        self.quality = quality
        self.sequence = sequence
    }
}
