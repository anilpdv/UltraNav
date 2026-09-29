import Foundation

enum HapticPattern: Equatable, Sendable {
    case rideStarted
    case ridePaused
    case rideResumed
    case rideFinished

    case turnApproaching
    case turnImmediate

    case possibleDeviation
    case offRoute
    case routeRejoined

    case climbApproaching
    case climbStarted
    case climbCompleted

    case error
}

protocol HapticProviding: Sendable {
    func play(
        _ pattern: HapticPattern
    ) async
}
