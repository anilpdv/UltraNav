import Foundation

struct RideTransition: Equatable, Sendable {
    let previousState: RideState
    let event: RideEvent
    let newState: RideState
    let effects: [RideEffect]

    var changedState: Bool {
        previousState != newState
    }
}
