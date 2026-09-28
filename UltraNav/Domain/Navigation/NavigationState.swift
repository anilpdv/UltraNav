import Foundation

enum NavigationState: Equatable, Sendable {
    case inactive
    case loading

    case ready

    case starting
    case navigating

    case suspectedOffRoute
    case offRoute
    case rejoining

    case finishing
    case finished

    case failed(
        failure: NavigationFailure,
        recovery: NavigationRecovery
    )
}

enum NavigationRecovery: Equatable, Sendable {
    case returnToInactive
    case returnToReady
    case returnToNavigating
    case retryLoading
    case none
}

enum NavigationStateName: String, Equatable, Sendable {
    case inactive
    case loading
    case ready
    case starting
    case navigating
    case suspectedOffRoute
    case offRoute
    case rejoining
    case finishing
    case finished
    case failed
}

extension NavigationState {
    var name: NavigationStateName {
        switch self {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .ready:
            return .ready
        case .starting:
            return .starting
        case .navigating:
            return .navigating
        case .suspectedOffRoute:
            return .suspectedOffRoute
        case .offRoute:
            return .offRoute
        case .rejoining:
            return .rejoining
        case .finishing:
            return .finishing
        case .finished:
            return .finished
        case .failed:
            return .failed
        }
    }
}
