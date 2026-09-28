import XCTest
@testable import UltraNav

@MainActor
final class RideEnginePauseResumeTests: XCTestCase {
    func testPauseRequiresActiveState() async {
        let harness = RideEngineHarness.make()
        await harness.prepareSuccessfully()

        await harness.engine.send(.pause)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)
    }

    func testPauseCallsWorkoutOnce() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.pause)

        let pauseCount = await harness.workout.pauseCallCount
        XCTAssertEqual(pauseCount, 1)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .paused)
        XCTAssertEqual(harness.engine.workoutStatus, .paused)
    }

    func testTimingStopsAccumulatingMovingTimeDuringPause() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.clock.advance(by: 100)
        await harness.engine.send(.pause)

        harness.clock.advance(by: 50)
        XCTAssertEqual(harness.engine.currentSnapshot.movingTimeSeconds, 100)
        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 150)
    }

    func testElapsedTimeContinuesDuringPause() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.clock.advance(by: 60)
        await harness.engine.send(.pause)

        harness.clock.advance(by: 60)
        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 120)
    }

    func testLocationRemainsActiveDuringPause() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.pause)

        let locStopCount = await harness.location.stopUpdatesCallCount
        XCTAssertEqual(locStopCount, 0)
        XCTAssertEqual(harness.engine.locationStatus, .active)
    }

    func testRideMetricLocationUpdatesAreIgnoredWhilePaused() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        await harness.engine.send(.pause)

        let sample = LocationSampleFactory.makeSample(speed: 10.0, altitude: 200.0)
        harness.location.send(.locationReceived(sample))

        await Task.yield()

        XCTAssertNil(harness.engine.currentSnapshot.metrics.currentSpeedMetersPerSecond)
        XCTAssertNil(harness.engine.currentSnapshot.metrics.altitudeMeters)
    }

    func testResumeRequiresPausedState() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        // Already active
        await harness.engine.send(.resume)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
    }

    func testResumeCallsWorkoutOnce() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.engine.send(.pause)

        await harness.engine.send(.resume)

        let resumeCount = await harness.workout.resumeCallCount
        XCTAssertEqual(resumeCount, 1)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
        XCTAssertEqual(harness.engine.workoutStatus, .active)
    }

    func testMovingTimeContinuesAfterResume() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()

        harness.clock.advance(by: 60)
        await harness.engine.send(.pause)

        harness.clock.advance(by: 30)
        await harness.engine.send(.resume)

        harness.clock.advance(by: 40)
        XCTAssertEqual(harness.engine.currentSnapshot.movingTimeSeconds, 100)
        XCTAssertEqual(harness.engine.currentSnapshot.elapsedTimeSeconds, 130)
    }

    func testPauseFailureCanRecoverToActive() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.workout.setPauseFailure(.pauseFailed)

        await harness.engine.send(.pause)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutPauseFailed, recovery: .returnToActive))

        await harness.engine.send(.recover)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
    }

    func testResumeFailureCanRecoverToPaused() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.engine.send(.pause)
        await harness.workout.setResumeFailure(.resumeFailed)

        await harness.engine.send(.resume)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutResumeFailed, recovery: .returnToPaused))

        await harness.engine.send(.recover)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .paused)
    }
}
