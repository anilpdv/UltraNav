import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineFreshnessTests {
    @Test
    func testFreshnessTransitionsFromFreshToStaleToExpired() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let initialTime = harness.clock.now
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 10.0, timestamp: initialTime))

        #expect(harness.engine.currentSnapshot.speed?.freshness == .fresh)
        #expect(harness.engine.currentSnapshot.availability.hasSpeed == true)

        // Advance by 6 seconds (stale threshold is 5s)
        harness.clock.advance(by: 6.0)
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: nil, timestamp: harness.clock.now))

        #expect(harness.engine.currentSnapshot.speed?.freshness == .stale)
        #expect(harness.engine.currentSnapshot.availability.hasSpeed == true)

        // Advance past expired threshold (15s total)
        harness.clock.advance(by: 10.0)
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: nil, timestamp: harness.clock.now))

        #expect(harness.engine.currentSnapshot.speed?.freshness == .expired)
        #expect(harness.engine.currentSnapshot.availability.hasSpeed == false)
    }
}
