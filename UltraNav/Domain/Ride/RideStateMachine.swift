import Foundation

struct RideStateMachine: Sendable {
    private(set) var state: RideState

    init(initialState: RideState = .idle) {
        self.state = initialState
    }

    @discardableResult
    mutating func handle(
        _ event: RideEvent
    ) throws -> RideTransition {
        let previousState = state
        let result = try transition(from: state, event: event)

        state = result.state

        return RideTransition(
            previousState: previousState,
            event: event,
            newState: result.state,
            effects: result.effects
        )
    }
}

private extension RideStateMachine {
    struct Result {
        let state: RideState
        let effects: [RideEffect]
    }

    func transition(
        from state: RideState,
        event: RideEvent
    ) throws -> Result {
        switch (state, event) {
        case (.idle, .prepareRequested):
            return Result(
                state: .preparing,
                effects: [.prepareDependencies]
            )

        case (.preparing, .preparationSucceeded):
            return Result(
                state: .ready,
                effects: []
            )

        case (.preparing, .preparationFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .returnToIdle
                ),
                effects: []
            )

        case (.ready, .startRequested):
            return Result(
                state: .starting,
                effects: [.startRide]
            )

        case (.starting, .startSucceeded):
            return Result(
                state: .active,
                effects: []
            )

        case (.starting, .startFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .returnToReady
                ),
                effects: []
            )

        case (.active, .pauseRequested):
            return Result(
                state: .pausing,
                effects: [.pauseRide]
            )

        case (.pausing, .pauseSucceeded):
            return Result(
                state: .paused,
                effects: []
            )

        case (.pausing, .pauseFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .returnToActive
                ),
                effects: []
            )

        case (.paused, .resumeRequested):
            return Result(
                state: .resuming,
                effects: [.resumeRide]
            )

        case (.resuming, .resumeSucceeded):
            return Result(
                state: .active,
                effects: []
            )

        case (.resuming, .resumeFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .returnToPaused
                ),
                effects: []
            )

        case (.active, .finishRequested),
             (.paused, .finishRequested):
            return Result(
                state: .finishing,
                effects: [.finishRide]
            )

        case (.finishing, .finishSucceeded):
            return Result(
                state: .completed,
                effects: []
            )

        case (.finishing, .finishFailed(let failure)):
            return Result(
                state: .failed(
                    failure: failure,
                    recovery: .retryFinishing
                ),
                effects: []
            )

        case (.completed, .resetRequested):
            return Result(
                state: .idle,
                effects: [.resetRide]
            )

        case (.failed(_, let recovery), .recoveryRequested):
            return try recoveryResult(for: recovery)

        case (.failed, .resetRequested):
            return Result(
                state: .idle,
                effects: [.resetRide]
            )

        default:
            throw RideTransitionError.invalidTransition(
                state: state.name,
                event: event.name
            )
        }
    }

    func recoveryResult(
        for recovery: RideRecovery
    ) throws -> Result {
        switch recovery {
        case .returnToIdle:
            return Result(
                state: .idle,
                effects: [.resetRide]
            )

        case .returnToReady:
            return Result(
                state: .ready,
                effects: []
            )

        case .returnToActive:
            return Result(
                state: .active,
                effects: []
            )

        case .returnToPaused:
            return Result(
                state: .paused,
                effects: []
            )

        case .retryFinishing:
            return Result(
                state: .finishing,
                effects: [.finishRide]
            )

        case .none:
            throw RideTransitionError.invalidTransition(
                state: .failed,
                event: .recoveryRequested
            )
        }
    }
}
