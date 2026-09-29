import Foundation
import Testing
@testable import UltraNav

@Suite("MetricArbitrator Tests")
struct MetricArbitratorTests {
    private let arbitrator = MetricArbitrator()
    private let policy = MetricSourcePolicy.outdoorCycling
    private let freshness = MetricFreshness.standard

    @Test("Selects highest priority source initially")
    func testInitialSelection() {
        var recovery: [MetricKind: Date] = [:]
        let date = Date(timeIntervalSince1970: 1000)

        let gpsObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(8.0),
            source: .gps,
            measuredAt: date
        )
        let wheelObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(8.2),
            source: .bluetooth(sensor: SensorIdentifier(rawValue: "wheel-1")),
            measuredAt: date
        )

        let result = arbitrator.select(
            kind: .speed,
            candidates: [gpsObs, wheelObs],
            currentSelection: nil,
            policy: policy,
            freshnessConfig: freshness,
            at: date,
            recoveryState: &recovery
        )

        #expect(result.selection?.source == .bluetooth(sensor: SensorIdentifier(rawValue: "wheel-1")))
        if case .initiallySelected(let src) = result.transition {
            #expect(src == .bluetooth(sensor: SensorIdentifier(rawValue: "wheel-1")))
        } else {
            Issue.record("Expected initiallySelected transition")
        }
    }

    @Test("Falls back to secondary source immediately when primary becomes stale")
    func testFallbackOnStale() {
        var recovery: [MetricKind: Date] = [:]
        let date = Date(timeIntervalSince1970: 1000)

        let wheelSource = MetricSource.bluetooth(sensor: SensorIdentifier(rawValue: "wheel-1"))
        let oldWheelObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(8.2),
            source: wheelSource,
            measuredAt: Date(timeIntervalSince1970: 980) // 20s old -> stale
        )
        let freshGpsObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(8.0),
            source: .gps,
            measuredAt: date // fresh
        )

        let currentSel = MetricSelection(
            source: wheelSource,
            observation: oldWheelObs,
            selectedAt: Date(timeIntervalSince1970: 980),
            preferenceRank: 0
        )

        let result = arbitrator.select(
            kind: .speed,
            candidates: [oldWheelObs, freshGpsObs],
            currentSelection: currentSel,
            policy: policy,
            freshnessConfig: freshness,
            at: date,
            recoveryState: &recovery
        )

        #expect(result.selection?.source == .gps)
        if case .currentSourceStale(let from, let to) = result.transition {
            #expect(from == wheelSource)
            #expect(to == .gps)
        } else {
            Issue.record("Expected currentSourceStale transition")
        }
    }

    @Test("Applies switch-back hysteresis delay when preferred source recovers")
    func testSwitchBackHysteresis() {
        var recovery: [MetricKind: Date] = [:]
        let wheelSource = MetricSource.bluetooth(sensor: SensorIdentifier(rawValue: "wheel-1"))

        let t0 = Date(timeIntervalSince1970: 1000)
        let gpsObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(8.0),
            source: .gps,
            measuredAt: t0
        )

        let currentSel = MetricSelection(
            source: .gps,
            observation: gpsObs,
            selectedAt: t0,
            preferenceRank: 1
        )

        // Preferred wheel sensor recovers at t0
        let recoveredWheelObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(8.3),
            source: wheelSource,
            measuredAt: t0
        )

        // Query at t0 (0s elapsed): should NOT switch back yet due to 3s delay
        let result1 = arbitrator.select(
            kind: .speed,
            candidates: [gpsObs, recoveredWheelObs],
            currentSelection: currentSel,
            policy: policy,
            freshnessConfig: freshness,
            at: t0,
            recoveryState: &recovery
        )
        #expect(result1.selection?.source == .gps)
        #expect(result1.transition == nil)

        // Query at t0 + 2.0s: still within hysteresis delay
        let t2 = t0.addingTimeInterval(2.0)
        let result2 = arbitrator.select(
            kind: .speed,
            candidates: [gpsObs, recoveredWheelObs],
            currentSelection: result1.selection,
            policy: policy,
            freshnessConfig: freshness,
            at: t2,
            recoveryState: &recovery
        )
        #expect(result2.selection?.source == .gps)

        // Query at t0 + 3.1s: hysteresis satisfied, switches back!
        let t3 = t0.addingTimeInterval(3.1)
        let result3 = arbitrator.select(
            kind: .speed,
            candidates: [gpsObs, recoveredWheelObs],
            currentSelection: result2.selection,
            policy: policy,
            freshnessConfig: freshness,
            at: t3,
            recoveryState: &recovery
        )
        #expect(result3.selection?.source == wheelSource)
        if case .preferredSourceAvailable(let from, let to) = result3.transition {
            #expect(from == .gps)
            #expect(to == wheelSource)
        } else {
            Issue.record("Expected preferredSourceAvailable transition")
        }
    }
}
