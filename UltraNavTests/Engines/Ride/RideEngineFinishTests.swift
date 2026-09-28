import XCTest
@testable import UltraNav

@MainActor
final class RideEngineFinishTests: XCTestCase {
    func testFinishAllowedFromActive() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .completed)
        XCTAssertEqual(harness.engine.workoutStatus, .ended)
    }

    func testFinishAllowedFromPaused() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.engine.send(.pause)

        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .completed)
    }

    func testFinishRejectedFromIdle() async {
        let harness = RideEngineHarness.make()
        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .idle)
    }

    func testFinishCapturesOneEndDate() async {
        let finishDate = Date(timeIntervalSince1970: 1_700_003_600)
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.clock.advance(by: 3600)
        await harness.engine.send(.finish)

        let finishDates = await harness.workout.finishDates
        XCTAssertEqual(finishDates.count, 1)
        XCTAssertEqual(harness.engine.currentSnapshot.endedAt, harness.clock.now)
    }

    func testLocationIsStoppedOnFinish() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.finish)

        let stopCount = await harness.location.stopUpdatesCallCount
        XCTAssertEqual(stopCount, 1)
    }

    func testWorkoutIsFinalizedOnFinish() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.finish)

        let finishDates = await harness.workout.finishDates
        XCTAssertEqual(finishDates.count, 1)
    }

    func testTimingEndsAtRequestDate() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.clock.advance(by: 1200)
        await harness.engine.send(.finish)

        harness.clock.advance(by: 500)
        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 1200)
        XCTAssertEqual(harness.engine.currentSnapshot.movingTimeSeconds, 1200)
    }

    func testSuccessfulFinishEntersCompleted() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .completed)
    }

    func testWorkoutFinalizationFailurePreservesRideMetrics() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.clock.advance(by: 1000)
        let sample = LocationSampleFactory.makeSample(speed: 8.0, altitude: 150.0)
        harness.location.send(.locationReceived(sample))
        await Task.yield()

        await harness.workout.setFinishFailure(.workoutSaveFailed)
        await harness.engine.send(.finish)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutFinishFailed, recovery: .retryFinishing))
        XCTAssertEqual(harness.engine.currentSnapshot.metrics.currentSpeedMetersPerSecond, 8.0)
        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 1000)
    }

    func testFailedFinishSupportsRetry() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.workout.setFinishFailure(.workoutSaveFailed)
        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutFinishFailed, recovery: .retryFinishing))

        await harness.workout.setFinishFailure(nil)
        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .completed)
    }

    func testDuplicateFinishDoesNotFinalizeTwice() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .completed)

        await harness.engine.send(.finish)
        let finishDates = await harness.workout.finishDates
        XCTAssertEqual(finishDates.count, 1)
    }
}
