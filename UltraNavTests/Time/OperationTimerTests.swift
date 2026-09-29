import Testing
import Foundation
@testable import UltraNav

@Suite("OperationTimer Tests")
struct OperationTimerTests {
    @Test("OperationTimer measures duration of throwing block")
    func testOperationTimerMeasuresThrowingBlock() async throws {
        let testClock = TestMonotonicClock(nanoseconds: 1_000_000_000)
        let timer = OperationTimer(clock: testClock)

        let result = try await timer.measure {
            testClock.advance(milliseconds: 250)
            return "success_value"
        }

        #expect(result.value == "success_value")
        #expect(result.duration == .nanoseconds(250_000_000))
    }

    @Test("OperationTimer measures non-throwing block")
    func testOperationTimerMeasuresNonThrowingBlock() async {
        let testClock = TestMonotonicClock(nanoseconds: 0)
        let timer = OperationTimer(clock: testClock)

        let result = await timer.measureNonThrowing {
            testClock.advance(milliseconds: 100)
            return 42
        }

        #expect(result.value == 42)
        #expect(result.duration == .nanoseconds(100_000_000))
    }
}
