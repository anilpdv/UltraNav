import Foundation

public enum RidePhaseViewState: String, Codable, Equatable, Sendable {
    case idle
    case preparing
    case ready
    case active
    case paused
    case finishing
    case completed
    case failed
}

public enum RideControlAction: String, Codable, Equatable, Sendable {
    case prepare
    case start
    case pause
    case resume
    case finish
    case retry
    case reset
}

public struct RideControlsState: Equatable, Sendable {
    public let primaryAction: RideControlAction?
    public let secondaryAction: RideControlAction?
    public let primaryEnabled: Bool
    public let secondaryEnabled: Bool
    public let showsFinishConfirmation: Bool

    public init(
        primaryAction: RideControlAction?,
        secondaryAction: RideControlAction?,
        primaryEnabled: Bool = true,
        secondaryEnabled: Bool = true,
        showsFinishConfirmation: Bool = false
    ) {
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.primaryEnabled = primaryEnabled
        self.secondaryEnabled = secondaryEnabled
        self.showsFinishConfirmation = showsFinishConfirmation
    }

    public static let idle = RideControlsState(
        primaryAction: .prepare,
        secondaryAction: nil,
        primaryEnabled: true,
        secondaryEnabled: false
    )

    public static let ready = RideControlsState(
        primaryAction: .start,
        secondaryAction: nil,
        primaryEnabled: true,
        secondaryEnabled: false
    )

    public static let active = RideControlsState(
        primaryAction: .pause,
        secondaryAction: .finish,
        primaryEnabled: true,
        secondaryEnabled: true
    )

    public static let paused = RideControlsState(
        primaryAction: .resume,
        secondaryAction: .finish,
        primaryEnabled: true,
        secondaryEnabled: true
    )

    public static let completed = RideControlsState(
        primaryAction: .reset,
        secondaryAction: nil,
        primaryEnabled: true,
        secondaryEnabled: false
    )

    public static let failed = RideControlsState(
        primaryAction: .retry,
        secondaryAction: .reset,
        primaryEnabled: true,
        secondaryEnabled: true
    )

    public static let transitional = RideControlsState(
        primaryAction: nil,
        secondaryAction: nil,
        primaryEnabled: false,
        secondaryEnabled: false
    )
}
