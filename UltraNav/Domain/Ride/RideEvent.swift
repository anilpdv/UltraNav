import Foundation

enum RideEvent: Equatable, Sendable {
    case prepareRequested
    case preparationSucceeded
    case preparationFailed(RideFailure)

    case startRequested
    case startSucceeded
    case startFailed(RideFailure)

    case pauseRequested
    case pauseSucceeded
    case pauseFailed(RideFailure)

    case resumeRequested
    case resumeSucceeded
    case resumeFailed(RideFailure)

    case finishRequested
    case finishSucceeded
    case finishFailed(RideFailure)

    case recoveryRequested
    case resetRequested
}

enum RideEventName: String, Equatable, Sendable {
    case prepareRequested
    case preparationSucceeded
    case preparationFailed

    case startRequested
    case startSucceeded
    case startFailed

    case pauseRequested
    case pauseSucceeded
    case pauseFailed

    case resumeRequested
    case resumeSucceeded
    case resumeFailed

    case finishRequested
    case finishSucceeded
    case finishFailed

    case recoveryRequested
    case resetRequested
}

extension RideEvent {
    var name: RideEventName {
        switch self {
        case .prepareRequested:
            return .prepareRequested
        case .preparationSucceeded:
            return .preparationSucceeded
        case .preparationFailed:
            return .preparationFailed

        case .startRequested:
            return .startRequested
        case .startSucceeded:
            return .startSucceeded
        case .startFailed:
            return .startFailed

        case .pauseRequested:
            return .pauseRequested
        case .pauseSucceeded:
            return .pauseSucceeded
        case .pauseFailed:
            return .pauseFailed

        case .resumeRequested:
            return .resumeRequested
        case .resumeSucceeded:
            return .resumeSucceeded
        case .resumeFailed:
            return .resumeFailed

        case .finishRequested:
            return .finishRequested
        case .finishSucceeded:
            return .finishSucceeded
        case .finishFailed:
            return .finishFailed

        case .recoveryRequested:
            return .recoveryRequested
        case .resetRequested:
            return .resetRequested
        }
    }
}
