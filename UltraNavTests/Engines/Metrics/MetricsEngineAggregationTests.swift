import Testing
import Foundation
@testable import UltraNav

@MainActor
struct MetricsEngineAggregationTests {
    @Test
    func testRollingAveragesAndMaximums() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let now = harness.clock.now
        let sensor = SensorIdentifier(rawValue: "power-01")

        harness.engine.consume(sensor: sensor, sample: .power(watts: 200, timestamp: now))
        harness.engine.consume(sensor: sensor, sample: .power(watts: 300, timestamp: now.addingTimeInterval(1)))
        harness.engine.consume(sensor: sensor, sample: .power(watts: 400, timestamp: now.addingTimeInterval(2)))

        let snap = harness.engine.currentSnapshot
        #expect(snap.averagePowerWatts == 300)
        #expect(snap.maxPowerWatts == 400)
    }

    @Test
    func testSpeedRollingAveragesAndMaximums() async {
        let harness = MetricsEngineHarness()
        await harness.engine.send(.start)

        let now = harness.clock.now
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 10.0, timestamp: now))
        harness.engine.consume(location: LocationSampleFactory.makeSample(speed: 20.0, timestamp: now.addingTimeInterval(1)))

        let snap = harness.engine.currentSnapshot
        #expect(snap.averageSpeedMetersPerSecond == 15.0)
        #expect(snap.maxSpeedMetersPerSecond == 20.0)
    }
}
