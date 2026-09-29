import Testing
import Foundation
@testable import UltraNav

@Suite("MonotonicClock Tests")
struct MonotonicClockTests {
    @Test("SystemMonotonicClock measures monotonically increasing duration")
    func testSystemMonotonicClock() {
        let clock = SystemMonotonicClock()
        let t1 = clock.now
        let t2 = clock.now

        #expect(t2 >= t1)
        let duration = clock.duration(from: t1, to: t2)
        #expect(duration >= .zero)
    }

    @Test("TestMonotonicClock advances deterministically")
    func testTestMonotonicClock() {
        let clock = TestMonotonicClock(nanoseconds: 1_000_000)
        let t1 = clock.now
        #expect(t1.nanoseconds == 1_000_000)

        clock.advance(milliseconds: 50.0) // 50,000,000 ns
        let t2 = clock.now
        #expect(t2.nanoseconds == 51_000_000)

        let duration = clock.duration(from: t1, to: t2)
        #expect(duration == .nanoseconds(50_000_000))
    }

    @Test("Negative delta returns zero duration")
    func testNegativeDeltaReturnsZero() {
        let clock = TestMonotonicClock(nanoseconds: 0)
        let t1 = MonotonicInstant(nanoseconds: 200)
        let t2 = MonotonicInstant(nanoseconds: 100)

        let duration = clock.duration(from: t1, to: t2)
        #expect(duration == .zero)
    }
}
