import Foundation

enum NavigationTransitionError: Error, Equatable, Sendable {
    case invalidTransition(
        state: NavigationStateName,
        event: NavigationEventName
    )
}
