import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineSourceTests {
    @Test
    func testSourceIdentityPreservedAcrossMultipleSensors() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let hrSensor = SensorIdentifier(rawValue: "chest-strap")
        let now = harness.clock.now

        harness.engine.consume(sensor: hrSensor, sample: .heartRate(beatsPerMinute: 155, timestamp: now))
        #expect(harness.engine.currentSnapshot.heartRate?.source == .bluetooth(sensorID: hrSensor))

        // HealthKit heart rate overrides/updates source identity
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 160.0, timestamp: now.addingTimeInterval(1)))
        #expect(harness.engine.currentSnapshot.heartRate?.source == .healthKit)
        #expect(harness.engine.currentSnapshot.heartRate?.value == 160)
    }
}
