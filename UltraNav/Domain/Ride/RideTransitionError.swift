import Foundation

enum RideTransitionError: Error, Equatable, Sendable {
    case invalidTransition(
        state: RideStateName,
        event: RideEventName
    )
}
