import Foundation
@testable import UltraNav

@MainActor
final class MetricsEngineBuilder {
    var validator: any MetricValidating = StandardMetricValidator()
    var arbitrator: any MetricArbitrating = MetricArbitrator()
    var freshnessEvaluator: any MetricFreshnessEvaluating = MetricFreshnessEvaluator()
    var configuration: MetricsConfiguration = .outdoorCycling
    var clock: any ClockProviding = TestClock()

    func withValidator(_ validator: any MetricValidating) -> Self {
        self.validator = validator
        return self
    }

    func withArbitrator(_ arbitrator: any MetricArbitrating) -> Self {
        self.arbitrator = arbitrator
        return self
    }

    func withConfiguration(_ config: MetricsConfiguration) -> Self {
        self.configuration = config
        return self
    }

    func withClock(_ clock: any ClockProviding) -> Self {
        self.clock = clock
        return self
    }

    func build() -> MetricsEngine {
        MetricsEngine(
            validator: validator,
            arbitrator: arbitrator,
            freshnessEvaluator: freshnessEvaluator,
            configuration: configuration,
            clock: clock
        )
    }
}
