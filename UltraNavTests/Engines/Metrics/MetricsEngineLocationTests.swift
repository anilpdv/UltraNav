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
        #expect(snap.speed?.source == .gps)
        #expect(snap.altitude?.value == 420.0)
        #expect(snap.altitude?.source == .gps)
        #expect(snap.availability.hasSpeed == true)
        #expect(snap.availability.hasAltitude == true)
    }

    @Test
    func testIdleEngineDoesNotAccumulateAverages() {
        let harness = MetricsEngineHarness()
        let sample = LocationSampleFactory.makeSample(speed: 15.5, altitude: 420.0, timestamp: harness.clock.now)
        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.speed?.value == 15.5)
        #expect(harness.engine.currentSnapshot.averageSpeedMetersPerSecond == nil)
        #expect(harness.engine.currentSnapshot.elapsedTimeSeconds == 0)
    }

    @Test
    func testPausedEngineDoesNotAccumulateAverages() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)
        await harness.engine.send(.pause)

        let sample = LocationSampleFactory.makeSample(speed: 15.5, altitude: 420.0, timestamp: harness.clock.now)
        harness.engine.consume(location: sample)

        #expect(harness.engine.currentSnapshot.speed?.value == 15.5)
        #expect(harness.engine.currentSnapshot.averageSpeedMetersPerSecond == nil)
    }
}
