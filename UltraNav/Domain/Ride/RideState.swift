import Foundation

enum RideState: Equatable, Sendable {
    case idle

    case preparing
    case ready

    case starting
    case active

    case pausing
    case paused

    case resuming

    case finishing
    case completed

    case failed(
        failure: RideFailure,
        recovery: RideRecovery
    )
}

enum RideRecovery: Equatable, Sendable {
    case returnToIdle
    case returnToReady
    case returnToActive
    case returnToPaused
    case retryFinishing
    case none
}

enum RideStateName: String, Equatable, Sendable {
    case idle
    case preparing
    case ready
    case starting
    case active
    case pausing
    case paused
    case resuming
    case finishing
    case completed
    case failed
}

extension RideState {
    var name: RideStateName {
        switch self {
        case .idle:
            return .idle
        case .preparing:
            return .preparing
        case .ready:
            return .ready
        case .starting:
            return .starting
        case .active:
            return .active
        case .pausing:
            return .pausing
        case .paused:
            return .paused
        case .resuming:
            return .resuming
        case .finishing:
            return .finishing
        case .completed:
            return .completed
        case .failed:
            return .failed
        }
    }
}

extension RideState {
    var hasPreparedRide: Bool {
        switch self {
        case .ready,
             .starting,
             .active,
             .pausing,
             .paused,
             .resuming,
             .finishing,
             .completed:
            return true

        case .idle,
             .preparing,
             .failed:
            return false
        }
    }

    var hasActiveRideSession: Bool {
        switch self {
        case .starting,
             .active,
             .pausing,
             .paused,
             .resuming,
             .finishing:
            return true

        case .idle,
             .preparing,
             .ready,
             .completed,
             .failed:
            return false
        }
    }

    var acceptsLocationSamples: Bool {
        switch self {
        case .active:
            return true

        default:
            return false
        }
    }

    var canRequestStart: Bool {
        self == .ready
    }

    var canRequestPause: Bool {
        self == .active
    }

    var canRequestResume: Bool {
        self == .paused
    }

    var canRequestFinish: Bool {
        self == .active || self == .paused
    }
}
