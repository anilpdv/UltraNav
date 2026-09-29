import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineIntegrationTests {
    @Test
    func testRideEngineAndLegacyAdapterIntegration() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let now = harness.clock.now
        let sensor = SensorIdentifier(rawValue: "power-01")

        harness.engine.consume(sensor: sensor, sample: .power(watts: 250, timestamp: now))
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 145, timestamp: now))
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 8.5, altitude: 150.0, timestamp: now))
        harness.engine.consume(workout: .cyclingDistance(meters: 1200, timestamp: now))

        let adapter = LegacyMetricsAdapter(engine: harness.engine)
        let rideMetrics = adapter.currentRideMetrics

        #expect(rideMetrics.powerWatts == 250)
        #expect(rideMetrics.heartRateBeatsPerMinute == 145)
        #expect(rideMetrics.currentSpeedMetersPerSecond == 8.5)
        #expect(rideMetrics.altitudeMeters == 150.0)
        #expect(rideMetrics.distanceMeters == 1200.0)
    }
}
