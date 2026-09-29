import Foundation

enum MetricFreshnessState: String, Codable, Equatable, Sendable {
    case fresh
    case stale
    case expired

    init(from availability: MetricAvailability) {
        switch availability {
        case .available: self = .fresh
        case .stale: self = .stale
        case .unavailable, .invalid: self = .expired
        }
    }
}

struct CurrentMetric<T: Equatable & Sendable>: Equatable, Sendable {
    let value: T
    let source: MetricSource
    let timestamp: Date
    let freshness: MetricFreshnessState

    init(
        value: T,
        source: MetricSource,
        timestamp: Date,
        freshness: MetricFreshnessState = .fresh
    ) {
        self.value = value
        self.source = source
        self.timestamp = timestamp
        self.freshness = freshness
    }
}
