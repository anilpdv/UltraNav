import XCTest
@testable import UltraNav

@MainActor
final class RideEngineTimingTests: XCTestCase {
    func testPausedTimeIsExcludedFromMovingTime() async {
        let startTime = Date(timeIntervalSince1970: 1_700_000_000)
        let harness = RideEngineHarness.make(now: startTime)

        await harness.prepareAndStart()

        harness.clock.advance(by: 3600) // 1 hr active
        await harness.engine.send(.pause)

        harness.clock.advance(by: 600)  // 10 min paused
        await harness.engine.send(.resume)

        harness.clock.advance(by: 1800) // 30 min active
        await harness.engine.send(.finish)

        let snapshot = harness.engine.currentSnapshot

        XCTAssertEqual(snapshot.elapsedTimeSeconds, 6000)
        XCTAssertEqual(snapshot.movingTimeSeconds, 5400)
    }

    func testElapsedTimeCalculatesFromStartToEndDate() async {
        let startTime = Date(timeIntervalSince1970: 1_700_000_000)
        let harness = RideEngineHarness.make(now: startTime)

        await harness.prepareAndStart()

        harness.clock.advance(by: 7200)
        await harness.engine.send(.finish)

        harness.clock.advance(by: 3600) // Clock advances after finish
        let snapshot = harness.engine.currentSnapshot

        XCTAssertEqual(snapshot.elapsedTimeSeconds, 7200)
        XCTAssertEqual(snapshot.movingTimeSeconds, 7200)
    }

    func testMovingTimeAccumulatesMultiplePauseSegments() async {
        let startTime = Date(timeIntervalSince1970: 1_700_000_000)
        let harness = RideEngineHarness.make(now: startTime)

        await harness.prepareAndStart()

        harness.clock.advance(by: 100)
        await harness.engine.send(.pause)

        harness.clock.advance(by: 50)
        await harness.engine.send(.resume)

        harness.clock.advance(by: 200)
        await harness.engine.send(.pause)

        harness.clock.advance(by: 50)
        await harness.engine.send(.resume)

        harness.clock.advance(by: 300)
        await harness.engine.send(.finish)

        let snapshot = harness.engine.currentSnapshot

        XCTAssertEqual(snapshot.elapsedTimeSeconds, 700)
        XCTAssertEqual(snapshot.movingTimeSeconds, 600)
    }
}
