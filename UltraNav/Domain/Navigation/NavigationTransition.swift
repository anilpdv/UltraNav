import Foundation

struct NavigationTransition: Equatable, Sendable {
    let previousState: NavigationState
    let event: NavigationEvent
    let newState: NavigationState
    let effects: [NavigationEffect]

    var changedState: Bool {
        previousState != newState
    }
}
