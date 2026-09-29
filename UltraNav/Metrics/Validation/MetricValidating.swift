import Foundation

protocol MetricValidating: Sendable {
    func validate(
        _ observation: MetricObservation,
        policy: MetricValidationPolicy
    ) -> MetricValidationResult
}
