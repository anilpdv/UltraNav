import Foundation
@testable import UltraNav

struct FakeMetricValidator: MetricValidating, Sendable {
    var isValid: Bool = true

    func validate(
        _ observation: MetricObservation,
        policy: MetricValidationPolicy
    ) -> MetricValidationResult {
        isValid ? .accepted(observation) : .rejected(.belowMinimum)
    }
}
