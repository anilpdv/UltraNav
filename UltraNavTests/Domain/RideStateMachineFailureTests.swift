import XCTest
@testable import UltraNav

final class RideStateMachineFailureTests: XCTestCase {
    func testPreparationFailureContainsRecoveryToIdle() throws {
        var machine = RideStateMachine(
            initialState: .preparing
        )

        let transition = try machine.handle(
            .preparationFailed(.workoutPreparationFailed)
        )

        XCTAssertEqual(
            transition.newState,
            .failed(
                failure: .workoutPreparationFailed,
                recovery: .returnToIdle
            )
        )
    }

    func testStartFailureCanRecoverToReady() throws {
        var machine = RideStateMachine(
            initialState: .starting
        )

        _ = try machine.handle(
            .startFailed(.workoutStartFailed)
        )

        let recovery = try machine.handle(
            .recoveryRequested
        )

        XCTAssertEqual(recovery.newState, .ready)
    }

    func testPauseFailureCanRecoverToActive() throws {
        var machine = RideStateMachine(
            initialState: .pausing
        )

        _ = try machine.handle(
            .pauseFailed(.workoutPauseFailed)
        )

        let recovery = try machine.handle(
            .recoveryRequested
        )

        XCTAssertEqual(recovery.newState, .active)
    }

    func testResumeFailureCanRecoverToPaused() throws {
        var machine = RideStateMachine(
            initialState: .resuming
        )

        _ = try machine.handle(
            .resumeFailed(.workoutResumeFailed)
        )

        let recovery = try machine.handle(
            .recoveryRequested
        )

        XCTAssertEqual(recovery.newState, .paused)
    }

    func testFinishFailureCanRetryFinishing() throws {
        var machine = RideStateMachine(
            initialState: .finishing
        )

        _ = try machine.handle(
            .finishFailed(.workoutFinishFailed)
        )

        let recovery = try machine.handle(
            .recoveryRequested
        )

        XCTAssertEqual(recovery.newState, .finishing)
        XCTAssertEqual(recovery.effects, [.finishRide])
    }

    func testPauseFromIdleIsRejected() {
        var machine = RideStateMachine()

        XCTAssertThrowsError(
            try machine.handle(.pauseRequested)
        ) { error in
            XCTAssertEqual(
                error as? RideTransitionError,
                .invalidTransition(
                    state: .idle,
                    event: .pauseRequested
                )
            )
        }

        XCTAssertEqual(machine.state, .idle)
    }

    func testDoubleStartRequestIsRejected() throws {
        var machine = RideStateMachine(
            initialState: .ready
        )

        _ = try machine.handle(.startRequested)

        XCTAssertThrowsError(
            try machine.handle(.startRequested)
        )

        XCTAssertEqual(machine.state, .starting)
    }

    func testInvalidTransitionDoesNotMutateState() {
        var machine = RideStateMachine(
            initialState: .completed
        )

        XCTAssertThrowsError(
            try machine.handle(.resumeRequested)
        )

        XCTAssertEqual(machine.state, .completed)
    }
}
