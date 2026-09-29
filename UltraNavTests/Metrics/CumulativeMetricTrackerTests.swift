import Foundation
import Testing
@testable import UltraNav

@Suite("CumulativeMetricTracker Tests")
struct CumulativeMetricTrackerTests {
    @Test("Maintains non-decreasing total across source switches with offsets")
    func testSourceSwitching() {
        var tracker = CumulativeMetricTracker()
        let t0 = Date(timeIntervalSince1970: 1000)

        // 1. GPS active: raw 5000m -> displayed 5000m
        tracker.selectSource(.gps, currentRawValue: 5000, at: t0)
        let d1 = tracker.consume(source: .gps, rawValue: 5000, at: t0)
        #expect(d1 == 5000)

        // 2. Switch to Wheel sensor with raw value 4900m
        // Offset = 5000 - 4900 = +100m. Displayed total should stay 5000m
        let wheelSource = MetricSource.bluetooth(sensor: SensorIdentifier(rawValue: "wheel-1"))
        tracker.selectSource(wheelSource, currentRawValue: 4900, at: t0)
        let d2 = tracker.consume(source: wheelSource, rawValue: 4900, at: t0)
        #expect(d2 == 5000)

        // 3. Wheel advances to raw 5000m -> displayed 5000 + 100 = 5100m
        let d3 = tracker.consume(source: wheelSource, rawValue: 5000, at: t0.addingTimeInterval(5))
        #expect(d3 == 5100)

        // 4. Wheel fails, switch back to GPS which is at raw 5080m
        // Offset = 5100 - 5080 = +20m. Displayed total should stay 5100m
        tracker.selectSource(.gps, currentRawValue: 5080, at: t0.addingTimeInterval(10))
        let d4 = tracker.consume(source: .gps, rawValue: 5080, at: t0.addingTimeInterval(10))
        #expect(d4 == 5100)

        // 5. GPS advances to raw 5150m -> displayed 5150 + 20 = 5170m
        let d5 = tracker.consume(source: .gps, rawValue: 5150, at: t0.addingTimeInterval(15))
        #expect(d5 == 5170)
    }

    @Test("Detects raw sensor reset and re-anchors without dropping total")
    func testSensorResetDetection() {
        var tracker = CumulativeMetricTracker()
        let t0 = Date(timeIntervalSince1970: 1000)

        let wheelSource = MetricSource.bluetooth(sensor: SensorIdentifier(rawValue: "wheel-1"))
        tracker.selectSource(wheelSource, currentRawValue: 10000, at: t0)
        _ = tracker.consume(source: wheelSource, rawValue: 10000, at: t0)
        #expect(tracker.displayedTotal == 10000)

        // Wheel sensor powers off and resets to raw 0
        let dReset = tracker.consume(source: wheelSource, rawValue: 0, at: t0.addingTimeInterval(5))
        #expect(dReset == 10000)

        // Advances to 50m
        let dAdvance = tracker.consume(source: wheelSource, rawValue: 50, at: t0.addingTimeInterval(10))
        #expect(dAdvance == 10050)
    }
}
