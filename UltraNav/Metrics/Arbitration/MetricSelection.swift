import Foundation

struct MetricSourceCandidate: Equatable, Sendable {
    let observation: MetricObservation
    let availability: MetricAvailability
    let preferenceRank: Int
    let qualityRank: Int
}

struct MetricSelection: Equatable, Sendable {
    let source: MetricSource
    let observation: MetricObservation
    let selectedAt: Date
    let preferenceRank: Int
}

enum MetricSourceTransition: Equatable, Sendable {
    case initiallySelected(MetricSource)
    case preferredSourceAvailable(from: MetricSource, to: MetricSource)
    case currentSourceStale(from: MetricSource, to: MetricSource?)
    case currentSourceUnavailable(from: MetricSource, to: MetricSource?)
    case manuallyChanged(from: MetricSource?, to: MetricSource?)
}

struct MetricArbitrationResult: Equatable, Sendable {
    let selection: MetricSelection?
    let transition: MetricSourceTransition?
}
