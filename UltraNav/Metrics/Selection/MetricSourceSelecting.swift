import Foundation

protocol MetricSourceSelecting: Sendable {
    func selectObservation(from candidates: [MetricObservation], now: Date) -> MetricObservation?
}

/// A temporary selector that matches Phase 1 legacy behavior (latest sample wins),
/// preparing for Phase 9 priority rules (BLE > HealthKit/CoreLocation).
struct TemporaryLatestSourceSelector: MetricSourceSelecting, Sendable {
    func selectObservation(from candidates: [MetricObservation], now: Date) -> MetricObservation? {
        candidates.max(by: { $0.timestamp < $1.timestamp })
    }
}
