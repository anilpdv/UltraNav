import Foundation
import Testing
@testable import UltraNav

@Suite("PowerSmoother Tests")
struct PowerSmootherTests {
    @Test("Calculates 3s, 10s, 30s rolling averages from time-weighted samples")
    func testRollingAverages() {
        var smoother = PowerSmoother()
        let t0 = Date(timeIntervalSince1970: 1000)

        // Add 10 samples, 1 second apart, at 200W
        for i in 0..<10 {
            smoother.consume(watts: 200.0, at: t0.addingTimeInterval(Double(i)))
        }

        let now = t0.addingTimeInterval(9)
        let avg3 = smoother.average(windowSeconds: 3.0, at: now)
        let avg10 = smoother.average(windowSeconds: 10.0, at: now)

        #expect(avg3 != nil)
        #expect(abs((avg3 ?? 0) - 200.0) < 0.1)
        #expect(avg10 != nil)
        #expect(abs((avg10 ?? 0) - 200.0) < 0.1)
    }

    @Test("Handles power changes and step transitions")
    func testStepTransition() {
        var smoother = PowerSmoother()
        let t0 = Date(timeIntervalSince1970: 1000)

        // 3 seconds at 100W
        smoother.consume(watts: 100.0, at: t0)
        smoother.consume(watts: 100.0, at: t0.addingTimeInterval(1))
        smoother.consume(watts: 100.0, at: t0.addingTimeInterval(2))

        // Step up to 300W for 2 seconds
        smoother.consume(watts: 300.0, at: t0.addingTimeInterval(3))
        smoother.consume(watts: 300.0, at: t0.addingTimeInterval(4))

        let now = t0.addingTimeInterval(4)
        // Over last 3s (t=1..4): 1s at 100W, 2s at 300W -> (100*1 + 300*2)/3 = 700/3 ≈ 233.3W
        let avg3 = smoother.average(windowSeconds: 3.0, at: now)
        #expect(avg3 != nil)
        #expect(abs((avg3 ?? 0) - 233.33) < 1.0)
    }
}
