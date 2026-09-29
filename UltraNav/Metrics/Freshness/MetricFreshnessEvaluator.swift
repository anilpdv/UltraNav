import Foundation

protocol MetricFreshnessEvaluating: Sendable {
    func availability(
        kind: MetricKind,
        measuredAt: Date?,
        currentDate: Date,
        configuration: MetricFreshness
    ) -> MetricAvailability
}

struct MetricFreshnessEvaluator: MetricFreshnessEvaluating, Sendable {
    func availability(
        kind: MetricKind,
        measuredAt: Date?,
        currentDate: Date,
        configuration: MetricFreshness
    ) -> MetricAvailability {
        guard let measuredAt else {
            return .unavailable
        }

        let age = currentDate.timeIntervalSince(measuredAt)

        // Far-future timestamp check (> 60s ahead)
        if age < -60.0 {
            return .invalid
        }

        let effectiveAge = max(0.0, age)
        let threshold = configuration.timeout(for: kind)

        if effectiveAge <= threshold {
            return .available
        } else {
            return .stale
        }
    }
}
