import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineAggregationTests {
    @Test
    func testRollingAveragesAndMaximums() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let t0 = harness.clock.now
        let sensor = SensorIdentifier(rawValue: "power-01")

        harness.engine.consume(sensor: sensor, sample: .power(watts: 200, timestamp: t0))

        let t1 = t0.addingTimeInterval(1)
        harness.clock.set(t1)
        harness.engine.consume(sensor: sensor, sample: .power(watts: 300, timestamp: t1))

        let t2 = t0.addingTimeInterval(2)
        harness.clock.set(t2)
        harness.engine.consume(sensor: sensor, sample: .power(watts: 400, timestamp: t2))

        let snap = harness.engine.currentSnapshot
        #expect(snap.averagePowerWatts == 250) // (200*1 + 300*1) / 2
        #expect(snap.maxPowerWatts == 400)
    }

    @Test
    func testSpeedRollingAveragesAndMaximums() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let t0 = harness.clock.now
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 10.0, timestamp: t0))

        let t1 = t0.addingTimeInterval(1)
        harness.clock.set(t1)
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 20.0, timestamp: t1))

        let snap = harness.engine.currentSnapshot
        #expect(snap.averageSpeedMetersPerSecond == 10.0) // 10.0 * 1 / 1
        #expect(snap.maxSpeedMetersPerSecond == 20.0)
    }
}
