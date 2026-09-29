import Foundation

struct NavigationStateMachine: Sendable {
    private(set) var state: NavigationState

    init(initialState: NavigationState = .inactive) {
        self.state = initialState
    }

    @discardableResult
    mutating func handle(
        _ event: NavigationEvent
    ) throws -> NavigationTransition {
        let previousState = state
        let result = try transition(from: state, event: event)

        state = result.state

        return NavigationTransition(
            previousState: previousState,
            event: event,
            newState: result.state,
            effects: result.effects
        )
    }
}

private extension NavigationStateMachine {
    struct Result {
        let state: NavigationState
        let effects: [NavigationEffect]
    }

    func transition(
        from state: NavigationState,
        event: NavigationEvent
    ) throws -> Result {
        switch (state, event) {
        case (.inactive, .routeLoadRequested):
            return Result(
                state: .loading,
                effects: [.loadRoute]
            )

        case (.loading, .routeLoadSucceeded):
            return Result(
                state: .ready,
                effects: []
            )

        case (.loading, .routeLoadFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .retryLoading
                ),
                effects: []
            )

        case (.ready, .navigationStartRequested):
            return Result(
                state: .starting,
                effects: [.initializeNavigation]
            )

        case (.starting, .navigationStartSucceeded):
            return Result(
                state: .navigating,
                effects: []
            )

        case (.starting, .navigationStartFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .returnToReady
                ),
                effects: []
            )

        case (.navigating, .possibleDeviationDetected):
            return Result(
                state: .suspectedOffRoute,
                effects: []
            )

        case (.suspectedOffRoute, .deviationConfirmed):
            return Result(
                state: .offRoute,
                effects: [.notifyOffRoute]
            )

        case (.suspectedOffRoute, .rejoinConfirmed):
            return Result(
                state: .navigating,
                effects: []
            )

        case (.offRoute, .rejoinDetected):
            return Result(
                state: .rejoining,
                effects: []
            )

        case (.rejoining, .rejoinConfirmed):
            return Result(
                state: .navigating,
                effects: [.notifyRouteRejoined]
            )

        case (.navigating, .routeCompleted),
             (.suspectedOffRoute, .routeCompleted),
             (.rejoining, .routeCompleted):
            return Result(
                state: .finishing,
                effects: [.finishNavigation]
            )

        case (.finishing, .finishSucceeded):
            return Result(
                state: .finished,
                effects: []
            )

        case (.finishing, .finishFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .returnToNavigating
                ),
                effects: []
            )

        case (.navigating, .navigationStopRequested),
             (.suspectedOffRoute, .navigationStopRequested),
             (.offRoute, .navigationStopRequested),
             (.rejoining, .navigationStopRequested),
             (.starting, .navigationStopRequested):
            return Result(
                state: .ready,
                effects: [.stopNavigation]
            )

        case (.ready, .routeClearRequested),
             (.finished, .routeClearRequested),
             (.failed, .routeClearRequested):
            return Result(
                state: .inactive,
                effects: [.clearNavigation]
            )

        case (.ready, .stopRequested),
             (.starting, .stopRequested),
             (.navigating, .stopRequested),
             (.suspectedOffRoute, .stopRequested),
             (.offRoute, .stopRequested),
             (.rejoining, .stopRequested),
             (.finished, .stopRequested),
             (.failed, .stopRequested),
             (.ready, .resetRequested),
             (.starting, .resetRequested),
             (.navigating, .resetRequested),
             (.suspectedOffRoute, .resetRequested),
             (.offRoute, .resetRequested),
             (.rejoining, .resetRequested),
             (.finished, .resetRequested),
             (.failed, .resetRequested):
            return Result(
                state: .inactive,
                effects: [.clearNavigation]
            )

        case (.failed(_, let recovery), .recoveryRequested):
            return try recoveryResult(for: recovery)

        default:
            throw NavigationTransitionError.invalidTransition(
                state: state.name,
                event: event.name
            )
        }
    }

    func recoveryResult(
        for recovery: NavigationRecovery
    ) throws -> Result {
        switch recovery {
        case .returnToInactive:
            return Result(
                state: .inactive,
                effects: [.clearNavigation]
            )

        case .returnToReady:
            return Result(
                state: .ready,
                effects: []
            )

        case .returnToNavigating:
            return Result(
                state: .navigating,
                effects: []
            )

        case .retryLoading:
            return Result(
                state: .loading,
                effects: [.loadRoute]
            )

        case .none:
            throw NavigationTransitionError.invalidTransition(
                state: .failed,
                event: .recoveryRequested
            )
        }
    }
}
