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

        // 1. Initial HealthKit observation selected immediately
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 145.0, timestamp: now))
        #expect(harness.engine.currentSnapshot.heartRate?.source == .healthKit)
        #expect(harness.engine.currentSnapshot.heartRate?.value == 145)

        // 2. Bluetooth HR connects. First observation starts switchBackDelay (3.0s)
        let t1 = now.addingTimeInterval(1)
        harness.clock.set(t1)
        harness.engine.consume(sensor: hrSensor, sample: .heartRate(beatsPerMinute: 155, timestamp: t1))

        // 3. After switchBackDelay (3.5s elapsed), Bluetooth HR takes over
        let t2 = t1.addingTimeInterval(3.5)
        harness.clock.set(t2)
        harness.engine.consume(sensor: hrSensor, sample: .heartRate(beatsPerMinute: 155, timestamp: t2))
        #expect(harness.engine.currentSnapshot.heartRate?.source == .bluetooth(sensorID: hrSensor))
        #expect(harness.engine.currentSnapshot.heartRate?.value == 155)

        // 4. Lower priority HealthKit arrives while Bluetooth is fresh -> Bluetooth remains selected
        let t3 = t2.addingTimeInterval(1)
        harness.clock.set(t3)
        harness.engine.consume(workout: .heartRate(beatsPerMinute: 160.0, timestamp: t3))
        #expect(harness.engine.currentSnapshot.heartRate?.source == .bluetooth(sensorID: hrSensor))
        #expect(harness.engine.currentSnapshot.heartRate?.value == 155)
    }
}
