import XCTest
@testable import UltraNav

final class TestClockTests: XCTestCase {
    func testClockCanAdvanceDeterministically() {
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let clock = TestClock(now: start)

        XCTAssertEqual(clock.now, start)

        clock.advance(by: 60)
        XCTAssertEqual(clock.now, start.addingTimeInterval(60))

        let newDate = Date(timeIntervalSince1970: 1_700_003_600)
        clock.set(newDate)
        XCTAssertEqual(clock.now, newDate)
    }

    func testClockConcurrentAccessIsThreadSafe() {
        let clock = TestClock(now: Date())
        let iterations = 1000

        DispatchQueue.concurrentPerform(iterations: iterations) { i in
            clock.advance(by: 1.0)
            _ = clock.now
        }

        XCTAssertNotNil(clock.now)
    }
}
