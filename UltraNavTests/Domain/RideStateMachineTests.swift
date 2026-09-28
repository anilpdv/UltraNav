import XCTest
@testable import UltraNav

final class RideStateMachineTests: XCTestCase {
    func testInitialStateIsIdle() {
        let machine = RideStateMachine()

        XCTAssertEqual(machine.state, .idle)
    }

    func testPrepareRequestTransitionsFromIdleToPreparing() throws {
        var machine = RideStateMachine()

        let transition = try machine.handle(.prepareRequested)

        XCTAssertEqual(transition.previousState, .idle)
        XCTAssertEqual(transition.newState, .preparing)
        XCTAssertEqual(
            transition.effects,
            [.prepareDependencies]
        )
        XCTAssertEqual(machine.state, .preparing)
    }

    func testSuccessfulPreparationTransitionsToReady() throws {
        var machine = RideStateMachine(
            initialState: .preparing
        )

        let transition = try machine.handle(
            .preparationSucceeded
        )

        XCTAssertEqual(transition.newState, .ready)
        XCTAssertTrue(transition.effects.isEmpty)
    }

    func testStartRequestTransitionsToStarting() throws {
        var machine = RideStateMachine(
            initialState: .ready
        )

        let transition = try machine.handle(
            .startRequested
        )

        XCTAssertEqual(transition.newState, .starting)
        XCTAssertEqual(transition.effects, [.startRide])
    }

    func testStartSuccessTransitionsToActive() throws {
        var machine = RideStateMachine(
            initialState: .starting
        )

        let transition = try machine.handle(
            .startSucceeded
        )

        XCTAssertEqual(transition.newState, .active)
    }

    func testPauseLifecycle() throws {
        var machine = RideStateMachine(
            initialState: .active
        )

        let requested = try machine.handle(.pauseRequested)

        XCTAssertEqual(requested.newState, .pausing)
        XCTAssertEqual(requested.effects, [.pauseRide])

        let succeeded = try machine.handle(.pauseSucceeded)

        XCTAssertEqual(succeeded.newState, .paused)
        XCTAssertTrue(succeeded.effects.isEmpty)
    }

    func testResumeLifecycle() throws {
        var machine = RideStateMachine(
            initialState: .paused
        )

        let requested = try machine.handle(.resumeRequested)

        XCTAssertEqual(requested.newState, .resuming)
        XCTAssertEqual(requested.effects, [.resumeRide])

        let succeeded = try machine.handle(.resumeSucceeded)

        XCTAssertEqual(succeeded.newState, .active)
    }

    func testActiveRideCanFinish() throws {
        var machine = RideStateMachine(
            initialState: .active
        )

        let requested = try machine.handle(.finishRequested)

        XCTAssertEqual(requested.newState, .finishing)
        XCTAssertEqual(requested.effects, [.finishRide])

        let succeeded = try machine.handle(.finishSucceeded)

        XCTAssertEqual(succeeded.newState, .completed)
    }

    func testPausedRideCanFinish() throws {
        var machine = RideStateMachine(
            initialState: .paused
        )

        let transition = try machine.handle(
            .finishRequested
        )

        XCTAssertEqual(transition.newState, .finishing)
        XCTAssertEqual(transition.effects, [.finishRide])
    }

    func testCompletedRideCanReset() throws {
        var machine = RideStateMachine(
            initialState: .completed
        )

        let transition = try machine.handle(
            .resetRequested
        )

        XCTAssertEqual(transition.newState, .idle)
        XCTAssertEqual(transition.effects, [.resetRide])
    }
}
