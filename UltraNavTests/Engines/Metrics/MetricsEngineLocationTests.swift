import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineLocationTests {
    @Test
    func testActiveEngineConsumesLocationSpeedAndAltitude() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let sample = LocationSampleFactory.makeSample(speed: 15.5, altitude: 420.0, timestamp: harness.clock.now)
        harness.engine.consume(location: sample)

        let snap = harness.engine.currentSnapshot
        #expect(snap.speed?.value == 15.5)
        #expect(snap.speed?.source == .coreLocation)
        #expect(snap.altitude?.value == 420.0)
        #expect(snap.altitude?.source == .coreLocation)
        #expect(snap.availability.hasSpeed == true)
        #expect(snap.availability.hasAltitude == true)
    }

    @Test
    func testIdleEngineIgnoresLocation() {
        let harness = MetricsEngineHarness()
        let sample = LocationSampleFactory.makeSample(speed: 15.5, altitude: 420.0, timestamp: harness.clock.now)
        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.speed == nil)
        #expect(harness.engine.currentSnapshot.altitude == nil)
    }

    @Test
    func testPausedEngineIgnoresLocation() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)
        await harness.engine.send(.pause)

        let sample = LocationSampleFactory.makeSample(speed: 15.5, altitude: 420.0, timestamp: harness.clock.now)
        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.speed == nil)
    }
}
