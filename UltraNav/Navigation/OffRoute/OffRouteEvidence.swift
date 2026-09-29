import Foundation

/// Internal mutable tracking state for evaluating consecutive off-route evidence over time.
struct OffRouteEvidence: Sendable {
    var consecutiveOffTrackCount: Int = 0
    var firstDeviationTimestamp: Date?
    var consecutiveRecoveryCount: Int = 0

    mutating func recordDeviation(at timestamp: Date) {
        consecutiveOffTrackCount += 1
        consecutiveRecoveryCount = 0
        if firstDeviationTimestamp == nil {
            firstDeviationTimestamp = timestamp
        }
    }

    mutating func recordRecovery() {
        consecutiveRecoveryCount += 1
        consecutiveOffTrackCount = 0
        firstDeviationTimestamp = nil
    }

    mutating func reset() {
        consecutiveOffTrackCount = 0
        firstDeviationTimestamp = nil
        consecutiveRecoveryCount = 0
    }

    func deviationDuration(currentTimestamp: Date) -> TimeInterval {
        guard let first = firstDeviationTimestamp else { return 0.0 }
        return max(0.0, currentTimestamp.timeIntervalSince(first))
    }
}
