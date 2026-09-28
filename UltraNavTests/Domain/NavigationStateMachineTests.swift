import XCTest
@testable import UltraNav

final class NavigationStateMachineTests: XCTestCase {
    func testLoadLifecycle() throws {
        var machine = NavigationStateMachine()

        let requested = try machine.handle(
            .routeLoadRequested
        )

        XCTAssertEqual(requested.newState, .loading)
        XCTAssertEqual(requested.effects, [.loadRoute])

        let succeeded = try machine.handle(
            .routeLoadSucceeded
        )

        XCTAssertEqual(succeeded.newState, .ready)
    }

    func testNavigationStartLifecycle() throws {
        var machine = NavigationStateMachine(
            initialState: .ready
        )

        let requested = try machine.handle(
            .navigationStartRequested
        )

        XCTAssertEqual(requested.newState, .starting)
        XCTAssertEqual(
            requested.effects,
            [.initializeNavigation]
        )

        let succeeded = try machine.handle(
            .navigationStartSucceeded
        )

        XCTAssertEqual(succeeded.newState, .navigating)
    }

    func testDeviationRequiresConfirmation() throws {
        var machine = NavigationStateMachine(
            initialState: .navigating
        )

        let suspected = try machine.handle(
            .possibleDeviationDetected
        )

        XCTAssertEqual(
            suspected.newState,
            .suspectedOffRoute
        )

        let confirmed = try machine.handle(
            .deviationConfirmed
        )

        XCTAssertEqual(confirmed.newState, .offRoute)
        XCTAssertEqual(
            confirmed.effects,
            [.notifyOffRoute]
        )
    }

    func testSuspectedDeviationCanReturnToNavigating() throws {
        var machine = NavigationStateMachine(
            initialState: .suspectedOffRoute
        )

        let transition = try machine.handle(
            .rejoinConfirmed
        )

        XCTAssertEqual(
            transition.newState,
            .navigating
        )
        XCTAssertTrue(transition.effects.isEmpty)
    }

    func testRejoinLifecycle() throws {
        var machine = NavigationStateMachine(
            initialState: .offRoute
        )

        let detected = try machine.handle(.rejoinDetected)

        XCTAssertEqual(detected.newState, .rejoining)

        let confirmed = try machine.handle(.rejoinConfirmed)

        XCTAssertEqual(confirmed.newState, .navigating)
        XCTAssertEqual(
            confirmed.effects,
            [.notifyRouteRejoined]
        )
    }

    func testRouteCompletionTransitionsThroughFinishing() throws {
        var machine = NavigationStateMachine(
            initialState: .navigating
        )

        let completion = try machine.handle(
            .routeCompleted
        )

        XCTAssertEqual(completion.newState, .finishing)
        XCTAssertEqual(
            completion.effects,
            [.finishNavigation]
        )

        let finished = try machine.handle(
            .finishSucceeded
        )

        XCTAssertEqual(finished.newState, .finished)
    }

    func testStartWithoutRouteIsRejected() {
        var machine = NavigationStateMachine()

        XCTAssertThrowsError(
            try machine.handle(.navigationStartRequested)
        )

        XCTAssertEqual(machine.state, .inactive)
    }

    func testStopRequestedFromAnyActiveStateReturnsToInactive() throws {
        let activeStates: [NavigationState] = [
            .ready,
            .starting,
            .navigating,
            .suspectedOffRoute,
            .offRoute,
            .rejoining
        ]

        for state in activeStates {
            var machine = NavigationStateMachine(initialState: state)
            let transition = try machine.handle(.stopRequested)
            XCTAssertEqual(transition.newState, .inactive)
            XCTAssertEqual(transition.effects, [.clearNavigation])
            XCTAssertEqual(machine.state, .inactive)
        }
    }
}
