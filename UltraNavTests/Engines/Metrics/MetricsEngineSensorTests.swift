import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineSensorTests {
    @Test
    func testActiveEngineConsumesSensorSamples() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let now = harness.clock.now
        let hrSensor = SensorIdentifier(rawValue: "hr-sensor")
        let powerSensor = SensorIdentifier(rawValue: "power-sensor")
        let cadenceSensor = SensorIdentifier(rawValue: "cadence-sensor")
        let speedSensor = SensorIdentifier(rawValue: "speed-sensor")

        harness.engine.consume(sensor: hrSensor, sample: .heartRate(beatsPerMinute: 162, timestamp: now))
        harness.engine.consume(sensor: powerSensor, sample: .power(watts: 285, timestamp: now))
        harness.engine.consume(sensor: cadenceSensor, sample: .cadence(revolutionsPerMinute: 88.0, timestamp: now))
        harness.engine.consume(sensor: speedSensor, sample: .speed(metersPerSecond: 10.5, timestamp: now))

        let snap = harness.engine.currentSnapshot
        #expect(snap.heartRate?.value == 162)
        #expect(snap.heartRate?.source == .bluetooth(sensorID: hrSensor))
        #expect(snap.power?.value == 285)
        #expect(snap.power?.source == .bluetooth(sensorID: powerSensor))
        #expect(snap.cadence?.value == 88.0)
        #expect(snap.cadence?.source == .bluetooth(sensorID: cadenceSensor))
        #expect(snap.speed?.value == 10.5)
        #expect(snap.speed?.source == .bluetooth(sensorID: speedSensor))

        #expect(snap.availability.hasHeartRate == true)
        #expect(snap.availability.hasPower == true)
        #expect(snap.availability.hasCadence == true)
        #expect(snap.availability.hasSpeed == true)
    }
}
