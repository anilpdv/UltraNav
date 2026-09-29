import Foundation

struct SelectedMetricState: Equatable, Sendable {
    let kind: MetricKind
    let value: MetricValue?
    let source: MetricSource?
    let availability: MetricAvailability
    let quality: MetricQuality?
    let measuredAt: Date?
    let receivedAt: Date?
    let sourceChangedAt: Date?

    init(
        kind: MetricKind,
        value: MetricValue? = nil,
        source: MetricSource? = nil,
        availability: MetricAvailability = .unavailable,
        quality: MetricQuality? = nil,
        measuredAt: Date? = nil,
        receivedAt: Date? = nil,
        sourceChangedAt: Date? = nil
    ) {
        self.kind = kind
        self.value = value
        self.source = source
        self.availability = availability
        self.quality = quality
        self.measuredAt = measuredAt
        self.receivedAt = receivedAt
        self.sourceChangedAt = sourceChangedAt
    }

    static func unavailable(for kind: MetricKind) -> SelectedMetricState {
        SelectedMetricState(kind: kind, availability: .unavailable)
    }
}
