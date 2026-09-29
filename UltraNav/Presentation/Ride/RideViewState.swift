import Foundation

public struct RideViewState: Equatable, Sendable {
    public let phase: RidePhaseViewState
    public let title: String
    public let controls: RideControlsState
    public let elapsedTime: String
    public let movingTime: String
    public let statusMessage: String?
    public let warning: BannerViewState?
    public let isInteractionDisabled: Bool

    public init(
        phase: RidePhaseViewState,
        title: String,
        controls: RideControlsState,
        elapsedTime: String,
        movingTime: String,
        statusMessage: String? = nil,
        warning: BannerViewState? = nil,
        isInteractionDisabled: Bool = false
    ) {
        self.phase = phase
        self.title = title
        self.controls = controls
        self.elapsedTime = elapsedTime
        self.movingTime = movingTime
        self.statusMessage = statusMessage
        self.warning = warning
        self.isInteractionDisabled = isInteractionDisabled
    }

    public static let initial = RideViewState(
        phase: .idle,
        title: "Ready to Ride",
        controls: .idle,
        elapsedTime: "00:00",
        movingTime: "00:00"
    )
}

public enum RidePresentationAction: Equatable, Sendable {
    case appeared
    case primaryControlSelected
    case secondaryControlSelected
    case finishConfirmed
    case finishCancelled
    case retrySelected
    case resetSelected
}
