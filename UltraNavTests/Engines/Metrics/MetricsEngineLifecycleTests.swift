import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineLifecycleTests {
    @Test
    func testInitialStateIsIdleAndEmpty() {
        let harness = MetricsEngineHarness()
        #expect(harness.engine.state == .idle)
        #expect(harness.engine.currentSnapshot == .empty)
    }

    @Test
    func testStartTransitionsToActive() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)
        #expect(harness.engine.state == .active)
    }

    @Test
    func testPauseAndResumeLifecycle() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)
        #expect(harness.engine.state == .active)

        await harness.engine.send(.pause)
        #expect(harness.engine.state == .paused)

        await harness.engine.send(.resume)
        #expect(harness.engine.state == .active)
    }

    @Test
    func testStopTransitionsToStopped() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)
        await harness.engine.send(.stop)
        #expect(harness.engine.state == .stopped)
    }

    @Test
    func testResetReturnsToIdleAndClearsState() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let sample = LocationSampleFactory.makeSample(speed: 12.0, altitude: 250.0, timestamp: harness.clock.now)
        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.speed?.value == 12.0)

        await harness.engine.send(.reset)
        #expect(harness.engine.state == .idle)
        #expect(harness.engine.currentSnapshot == .empty)
    }
}
