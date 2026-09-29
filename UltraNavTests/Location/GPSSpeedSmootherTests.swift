import XCTest
@testable import UltraNav

final class GPSSpeedSmootherTests: XCTestCase {
    private var smoother: TimeWeightedSpeedSmoother!

    override func setUp() {
        super.setUp()
        smoother = TimeWeightedSpeedSmoother(windowSeconds: 5.0)
    }

    func testSingleSpeedReturnsDirectly() {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        smoother.add(speedMetersPerSecond: 10.0, at: t0)

        let value = smoother.value(at: t0)
        XCTAssertEqual(value, 10.0)
    }

    func testAveragesWithinSlidingWindow() {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        let t1 = Date(timeIntervalSince1970: 1700000001)
        let t2 = Date(timeIntervalSince1970: 1700000002)

        smoother.add(speedMetersPerSecond: 10.0, at: t0)
        smoother.add(speedMetersPerSecond: 12.0, at: t1)
        smoother.add(speedMetersPerSecond: 14.0, at: t2)

        let value = smoother.value(at: t2)
        XCTAssertNotNil(value)
        XCTAssertEqual(value!, 12.0, accuracy: 0.001) // (10 + 12 + 14) / 3 = 12.0
    }

    func testDiscardsSamplesBeyondWindow() {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        let t6 = Date(timeIntervalSince1970: 1700000006) // 6 seconds later (> 5s window)

        smoother.add(speedMetersPerSecond: 10.0, at: t0)
        smoother.add(speedMetersPerSecond: 20.0, at: t6)

        let value = smoother.value(at: t6)
        XCTAssertEqual(value, 20.0) // t0 should be excluded
    }

    func testResetClearsWindow() {
        let t0 = Date(timeIntervalSince1970: 1700000000)
        smoother.add(speedMetersPerSecond: 10.0, at: t0)
        smoother.reset()

        XCTAssertNil(smoother.value(at: t0))
    }
}
