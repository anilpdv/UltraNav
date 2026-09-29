import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineResetTests {
    @Test
    func testResetClearsAllBuffersAndSnapshots() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let now = harness.clock.now
        let sensor = SensorIdentifier(rawValue: "power-01")
        harness.engine.consume(sensor: sensor, sample: .power(watts: 350, timestamp: now))
        harness.engine.consume(workout: .cyclingDistance(meters: 5000, timestamp: now))

        #expect(harness.engine.currentSnapshot.power?.value == 350)
        #expect(harness.engine.currentSnapshot.distance?.value == 5000)

        await harness.engine.send(.reset)

        #expect(harness.engine.state == .idle)
        #expect(harness.engine.currentSnapshot == .empty)
        #expect(harness.engine.currentSnapshot.averagePowerWatts == nil)
    }
}
