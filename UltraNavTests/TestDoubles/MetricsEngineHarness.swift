import Foundation
@testable import UltraNav

@MainActor
final class MetricsEngineHarness {
    let engine: MetricsEngine
    let clock: TestClock
    let validator: FakeMetricValidator
    let sourceSelector: FakeMetricSourceSelector
    let snapshotRecorder: MetricsSnapshotRecorder

    init(
        now: Date = Date(timeIntervalSince1970: 1_000_000)
    ) {
        let clock = TestClock(now: now)
        let validator = FakeMetricValidator()
        let sourceSelector = FakeMetricSourceSelector()
        let summaryBuilder = MetricsSummaryBuilder()

        let engine = MetricsEngine(
            validator: validator,
            sourceSelector: sourceSelector,
            summaryBuilder: summaryBuilder,
            clock: clock
        )

        self.engine = engine
        self.clock = clock
        self.validator = validator
        self.sourceSelector = sourceSelector
        self.snapshotRecorder = MetricsSnapshotRecorder(stream: engine.snapshots)
    }
}
