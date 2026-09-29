import Foundation
import Testing
@testable import UltraNav

@Suite("MetricFreshness Tests")
struct MetricFreshnessTests {
    private let evaluator = MetricFreshnessEvaluator()
    private let config = MetricFreshness(
        speedSeconds: 5.0,
        heartRateSeconds: 10.0,
        cadenceSeconds: 5.0,
        powerSeconds: 3.0,
        altitudeSeconds: 10.0,
        cumulativeDistanceSeconds: 15.0,
        activeEnergySeconds: 30.0
    )

    @Test("Returns available when observation is within freshness threshold")
    func testAvailable() {
        let baseDate = Date(timeIntervalSince1970: 1000)
        let sampleDate = Date(timeIntervalSince1970: 998) // 2s old

        let avail = evaluator.availability(
            kind: .power,
            measuredAt: sampleDate,
            currentDate: baseDate,
            configuration: config
        )
        #expect(avail == .available)
    }

    @Test("Returns stale when observation exceeds freshness threshold")
    func testStale() {
        let baseDate = Date(timeIntervalSince1970: 1000)
        let sampleDate = Date(timeIntervalSince1970: 995) // 5s old (threshold is 3s for power)

        let avail = evaluator.availability(
            kind: .power,
            measuredAt: sampleDate,
            currentDate: baseDate,
            configuration: config
        )
        #expect(avail == .stale)
    }

    @Test("Returns unavailable when no measurement date exists")
    func testUnavailable() {
        let baseDate = Date(timeIntervalSince1970: 1000)
        let avail = evaluator.availability(
            kind: .power,
            measuredAt: nil,
            currentDate: baseDate,
            configuration: config
        )
        #expect(avail == .unavailable)
    }

    @Test("Returns invalid for far future timestamps")
    func testInvalidFarFuture() {
        let baseDate = Date(timeIntervalSince1970: 1000)
        let sampleDate = Date(timeIntervalSince1970: 1200) // 200s in the future

        let avail = evaluator.availability(
            kind: .power,
            measuredAt: sampleDate,
            currentDate: baseDate,
            configuration: config
        )
        #expect(avail == .invalid)
    }
}
