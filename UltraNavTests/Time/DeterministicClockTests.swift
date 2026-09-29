import Testing
import Foundation
@testable import UltraNav

@Suite("DeterministicClock Tests")
struct DeterministicClockTests {
    @Test("TestClock advances deterministically")
    func testTestClockAdvancesDeterministically() {
        let baseDate = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = TestClock(now: baseDate)

        #expect(clock.now == baseDate)

        clock.advance(by: 10.0)
        #expect(clock.now == baseDate.addingTimeInterval(10.0))

        let newDate = Date(timeIntervalSince1970: 1_800_000_000)
        clock.set(newDate)
        #expect(clock.now == newDate)
    }
}
