import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineIntegrationTests {
    @Test
    func testRideEngineMetricsIntegration() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let now = harness.clock.now
        let sensor = SensorIdentifier(rawValue: "power-01")

        harness.engine.consume(sensor: sensor, sample: .power(watts: 250, timestamp: now))
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 145, timestamp: now))
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 8.5, altitude: 150.0, timestamp: now))
        harness.engine.consume(workout: .cyclingDistance(meters: 1200, timestamp: now))

        let snapshot = harness.engine.currentSnapshot

        #expect(snapshot.power?.value == 250)
        #expect(snapshot.heartRate?.value == 145)
        #expect(snapshot.speed?.value == 8.5)
        #expect(snapshot.altitude?.value == 150.0)
        #expect(snapshot.distance?.value == 1200.0)
    }
}
