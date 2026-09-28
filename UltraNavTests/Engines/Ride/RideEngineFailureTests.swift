import XCTest
@testable import UltraNav

@MainActor
final class RideEngineFailureTests: XCTestCase {
    func testLocationDeniedBeforeStartEntersFailed() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.denied)
        await harness.workout.setStubbedAuthorizationStatus(.authorized)

        await harness.engine.send(.prepare)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationPermissionDenied, recovery: .returnToIdle))
    }

    func testWorkoutDeniedBeforeStartEntersFailed() async {
        let harness = RideEngineHarness.make()
        await harness.location.setStubbedAuthorizationStatus(.authorized)
        await harness.workout.setStubbedAuthorizationStatus(.denied)

        await harness.engine.send(.prepare)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutAuthorizationDenied, recovery: .returnToIdle))
    }

    func testStartFailureRollback() async {
        let harness = RideEngineHarness.make()
        await harness.prepareSuccessfully()
        await harness.location.setStartFailure(.servicesDisabled)

        await harness.engine.send(.start)

        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationUnavailable, recovery: .returnToReady))
        let cancelCount = await harness.workout.cancelCallCount
        XCTAssertEqual(cancelCount, 1)
    }

    func testRecoveryFromStartFailureReturnsToReady() async {
        let harness = RideEngineHarness.make()
        await harness.prepareSuccessfully()
        await harness.location.setStartFailure(.servicesDisabled)

        await harness.engine.send(.start)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .locationUnavailable, recovery: .returnToReady))

        await harness.engine.send(.recover)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .ready)
        XCTAssertNil(harness.engine.activeFailure)
    }

    func testRecoveryFromPauseFailureReturnsToActive() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.workout.setPauseFailure(.pauseFailed)

        await harness.engine.send(.pause)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutPauseFailed, recovery: .returnToActive))

        await harness.engine.send(.recover)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .active)
        XCTAssertNil(harness.engine.activeFailure)
    }

    func testRecoveryFromResumeFailureReturnsToPaused() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.engine.send(.pause)
        await harness.workout.setResumeFailure(.resumeFailed)

        await harness.engine.send(.resume)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutResumeFailed, recovery: .returnToPaused))

        await harness.engine.send(.recover)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .paused)
        XCTAssertNil(harness.engine.activeFailure)
    }

    func testRecoveryFromFinishFailureRetriesFinishing() async {
        let harness = RideEngineHarness.make()
        await harness.prepareAndStart()
        await harness.workout.setFinishFailure(.workoutSaveFailed)

        await harness.engine.send(.finish)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .failed(failure: .workoutFinishFailed, recovery: .retryFinishing))

        await harness.workout.setFinishFailure(nil)
        await harness.engine.send(.recover)
        XCTAssertEqual(harness.engine.currentSnapshot.state, .completed)
    }
}
