import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineWorkoutTests {
    @Test
    func testActiveEngineConsumesHeartRateDistanceEnergy() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let now = harness.clock.now
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 148.2, timestamp: now))
        harness.engine.consume(workout: .cyclingDistance(meters: 2500.0, timestamp: now))
        harness.engine.consume(workout: .activeEnergy(kilocalories: 120.0, timestamp: now))

        let snap = harness.engine.currentSnapshot
        #expect(snap.heartRate?.value == 148)
        #expect(snap.heartRate?.source == .healthKit)
        #expect(snap.distance?.value == 2500.0)
        #expect(snap.distance?.source == .healthKit)
        #expect(snap.energy?.value == 120.0)
        #expect(snap.energy?.source == .healthKit)
        #expect(snap.totalKilocalories == 120.0)
        #expect(snap.availability.hasHeartRate == true)
        #expect(snap.availability.hasDistance == true)
        #expect(snap.availability.hasEnergy == true)
    }

    @Test
    func testIdleEngineIgnoresWorkoutMetrics() {
        let harness = MetricsEngineHarness()
        let now = harness.clock.now
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 148.0, timestamp: now))

        #expect(harness.engine.currentSnapshot.heartRate == nil)
    }
}
