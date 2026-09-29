import Foundation
@testable import UltraNav

@MainActor
final class MetricsEngineHarness {
    let engine: MetricsEngine
    let clock: TestClock
    let validator: FakeMetricValidator
    let arbitrator: MetricArbitrator
    let snapshotRecorder: MetricsSnapshotRecorder

    init(
        now: Date = Date(timeIntervalSince1970: 1_000_000),
        configuration: MetricsConfiguration = .outdoorCycling
    ) {
        let clock = TestClock(now: now)
        let validator = FakeMetricValidator()
        let arbitrator = MetricArbitrator()
        let summaryBuilder = RideSummaryBuilder()

        let engine = MetricsEngine(
            validator: validator,
            arbitrator: arbitrator,
            configuration: configuration,
            clock: clock,
            summaryBuilder: summaryBuilder
        )

        self.engine = engine
        self.clock = clock
        self.validator = validator
        self.arbitrator = arbitrator
        self.snapshotRecorder = MetricsSnapshotRecorder(stream: engine.snapshots)
    }
}
