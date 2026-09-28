import Foundation

enum NavigationEvent: Equatable, Sendable {
    case routeLoadRequested
    case routeLoadSucceeded
    case routeLoadFailed(NavigationFailure)

    case navigationStartRequested
    case navigationStartSucceeded
    case navigationStartFailed(NavigationFailure)

    case possibleDeviationDetected
    case deviationConfirmed
    case rejoinDetected
    case rejoinConfirmed

    case routeCompleted
    case finishSucceeded
    case finishFailed(NavigationFailure)

    case stopRequested
    case resetRequested
    case recoveryRequested
}

enum NavigationEventName: String, Equatable, Sendable {
    case routeLoadRequested
    case routeLoadSucceeded
    case routeLoadFailed

    case navigationStartRequested
    case navigationStartSucceeded
    case navigationStartFailed

    case possibleDeviationDetected
    case deviationConfirmed
    case rejoinDetected
    case rejoinConfirmed

    case routeCompleted
    case finishSucceeded
    case finishFailed

    case stopRequested
    case resetRequested
    case recoveryRequested
}

extension NavigationEvent {
    var name: NavigationEventName {
        switch self {
        case .routeLoadRequested:
            return .routeLoadRequested
        case .routeLoadSucceeded:
            return .routeLoadSucceeded
        case .routeLoadFailed:
            return .routeLoadFailed

        case .navigationStartRequested:
            return .navigationStartRequested
        case .navigationStartSucceeded:
            return .navigationStartSucceeded
        case .navigationStartFailed:
            return .navigationStartFailed

        case .possibleDeviationDetected:
            return .possibleDeviationDetected
        case .deviationConfirmed:
            return .deviationConfirmed
        case .rejoinDetected:
            return .rejoinDetected
        case .rejoinConfirmed:
            return .rejoinConfirmed

        case .routeCompleted:
            return .routeCompleted
        case .finishSucceeded:
            return .finishSucceeded
        case .finishFailed:
            return .finishFailed

        case .stopRequested:
            return .stopRequested
        case .resetRequested:
            return .resetRequested
        case .recoveryRequested:
            return .recoveryRequested
        }
    }
}
