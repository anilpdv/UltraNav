import XCTest
@testable import UltraNav

final class NavigationStateMachineFailureTests: XCTestCase {
    func testRouteLoadFailureCanRetryLoading() throws {
        var machine = NavigationStateMachine(
            initialState: .loading
        )

        let transition = try machine.handle(
            .routeLoadFailed(.routeUnavailable)
        )

        XCTAssertEqual(
            transition.newState,
            .failed(
                failure: .routeUnavailable,
                recovery: .retryLoading
            )
        )

        let recovery = try machine.handle(.recoveryRequested)
        XCTAssertEqual(recovery.newState, .loading)
        XCTAssertEqual(recovery.effects, [.loadRoute])
    }

    func testStartFailureCanRecoverToReady() throws {
        var machine = NavigationStateMachine(
            initialState: .starting
        )

        _ = try machine.handle(
            .navigationStartFailed(.calculationFailed)
        )

        let recovery = try machine.handle(.recoveryRequested)
        XCTAssertEqual(recovery.newState, .ready)
        XCTAssertTrue(recovery.effects.isEmpty)
    }

    func testFinishFailureCanRecoverToNavigating() throws {
        var machine = NavigationStateMachine(
            initialState: .finishing
        )

        _ = try machine.handle(
            .finishFailed(.unexpected)
        )

        let recovery = try machine.handle(.recoveryRequested)
        XCTAssertEqual(recovery.newState, .navigating)
    }

    func testInvalidTransitionDoesNotMutateState() {
        var machine = NavigationStateMachine(
            initialState: .inactive
        )

        XCTAssertThrowsError(
            try machine.handle(.deviationConfirmed)
        ) { error in
            XCTAssertEqual(
                error as? NavigationTransitionError,
                .invalidTransition(
                    state: .inactive,
                    event: .deviationConfirmed
                )
            )
        }

        XCTAssertEqual(machine.state, .inactive)
    }

    func testFailedStateCanResetToInactive() throws {
        var machine = NavigationStateMachine(
            initialState: .failed(
                failure: .unexpected,
                recovery: .none
            )
        )

        let reset = try machine.handle(.resetRequested)
        XCTAssertEqual(reset.newState, .inactive)
        XCTAssertEqual(reset.effects, [.clearNavigation])
        XCTAssertEqual(machine.state, .inactive)
    }
}
