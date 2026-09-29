import Testing
import Foundation
@testable import UltraNav

@Suite("CounterMetric Tests")
struct CounterMetricTests {
    @Test("Counters increment correctly and appear in snapshot")
    func testCountersIncrement() async {
        let center = FakeObservabilityCenter()

        await center.increment(.locationSamplesReceived, by: 5)
        await center.increment(.locationSamplesReceived, by: 3)
        await center.increment(.sensorPacketsMalformed, by: 1)

        let snapshot = await center.snapshot()
        #expect(snapshot.counters[.locationSamplesReceived] == 8)
        #expect(snapshot.counters[.sensorPacketsMalformed] == 1)
        #expect(snapshot.counters[.routeImportsSucceeded] == nil)
    }
}
