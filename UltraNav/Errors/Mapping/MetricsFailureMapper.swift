import Foundation

struct MetricsFailureMapper: FailureClassifying {
    typealias Failure = MetricsFailure

    func classify(failure: MetricsFailure, context: FailureContext) -> FailureClassification {
        switch failure {
        case .invalidObservation(let message):
            return FailureClassification(
                id: .metricObservationInvalid,
                severity: .informational,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Invalid metric observation discarded: \(message)"
            )

        case .sourceStale(let message):
            return FailureClassification(
                id: .metricSourceStale,
                severity: .informational,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Metric source is stale: \(message)"
            )

        case .aggregationFailed(let message):
            return FailureClassification(
                id: .metricAggregationFailed,
                severity: .warning,
                impact: .degradesActiveRide,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Metric rolling calculation error: \(message)"
            )

        case .unexpected:
            return FailureClassification(
                id: FailureID(rawValue: "METRIC-UNEXPECTED-001"),
                severity: .informational,
                impact: .none,
                recoverability: .automatic,
                suggestedActions: [.dismiss],
                diagnosticMessage: "Unexpected metrics engine error"
            )
        }
    }
}
