import Foundation

enum MetricFreshness: Equatable, Sendable {
    case fresh
    case stale
    case expired

    static func freshness(
        for timestamp: Date,
        now: Date,
        staleThresholdSeconds: TimeInterval = 5.0,
        expiredThresholdSeconds: TimeInterval = 15.0
    ) -> MetricFreshness {
        let age = max(0, now.timeIntervalSince(timestamp))
        if age <= staleThresholdSeconds {
            return .fresh
        } else if age <= expiredThresholdSeconds {
            return .stale
        } else {
            return .expired
        }
    }
}
