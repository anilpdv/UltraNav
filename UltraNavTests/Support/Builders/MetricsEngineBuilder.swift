import Foundation
@testable import UltraNav

@MainActor
final class MetricsEngineBuilder {
    var validator: any MetricValidating = StandardMetricValidator()
    var sourceSelector: any MetricSourceSelecting = TemporaryLatestSourceSelector()
    var summaryBuilder: MetricsSummaryBuilder = MetricsSummaryBuilder()
    var clock: any ClockProviding = TestClock()

    func withValidator(_ validator: any MetricValidating) -> Self {
        self.validator = validator
        return self
    }

    func withSourceSelector(_ selector: any MetricSourceSelecting) -> Self {
        self.sourceSelector = selector
        return self
    }

    func withClock(_ clock: any ClockProviding) -> Self {
        self.clock = clock
        return self
    }

    func build() -> MetricsEngine {
        MetricsEngine(
            validator: validator,
            sourceSelector: sourceSelector,
            summaryBuilder: summaryBuilder,
            clock: clock
        )
    }
}
