import Testing
import Foundation
@testable import UltraNav

@Suite("SystemClock Tests")
struct SystemClockTests {
    @Test("SystemClock returns current system date")
    func testSystemClockReturnsCurrentDate() {
        let clock = SystemClock()
        let before = Date()
        let now = clock.now
        let after = Date()

        #expect(now >= before)
        #expect(now <= after)
    }
}
