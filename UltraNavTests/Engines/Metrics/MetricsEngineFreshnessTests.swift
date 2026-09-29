import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineFreshnessTests {
    @Test
    func testFreshnessTransitionsFromFreshToStale() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let initialTime = harness.clock.now
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 10.0, timestamp: initialTime))

        #expect(harness.engine.currentSnapshot.speed?.freshness == .fresh)
        #expect(harness.engine.currentSnapshot.availability.hasSpeed == true)

        // Advance by 6 seconds (threshold is 5s for speed)
        harness.clock.advance(by: 6.0)
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: nil, timestamp: harness.clock.now))

        #expect(harness.engine.currentSnapshot.speed?.freshness == .stale)
        #expect(harness.engine.currentSnapshot.availability.hasSpeed == true)
    }
}
