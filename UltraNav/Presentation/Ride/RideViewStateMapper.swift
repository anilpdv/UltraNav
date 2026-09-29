import Foundation

public struct RideViewStateMapper: Sendable {
    private let durationFormatter: any DurationFormatting

    public init(durationFormatter: any DurationFormatting = StandardDurationFormatter()) {
        self.durationFormatter = durationFormatter
    }

    func map(
        snapshot: RideSnapshot,
        showsFinishConfirmation: Bool = false
    ) -> RideViewState {
        let phase = mapPhase(snapshot.state)
        let controls = mapControls(snapshot.state, showsFinishConfirmation: showsFinishConfirmation)
        let elapsedTime = durationFormatter.formatDuration(seconds: snapshot.elapsedTimeSeconds)
        let movingTime = durationFormatter.formatDuration(seconds: snapshot.movingTimeSeconds)
        let title = mapTitle(phase)
        let statusMessage = mapStatusMessage(snapshot)
        let warning = mapWarning(snapshot)
        let isInteractionDisabled = isTransitional(snapshot.state)

        return RideViewState(
            phase: phase,
            title: title,
            controls: controls,
            elapsedTime: elapsedTime,
            movingTime: movingTime,
            statusMessage: statusMessage,
            warning: warning,
            isInteractionDisabled: isInteractionDisabled
        )
    }

    private func mapPhase(_ state: RideState) -> RidePhaseViewState {
        switch state {
        case .idle: return .idle
        case .preparing: return .preparing
        case .ready: return .ready
        case .starting, .active: return .active
        case .pausing, .paused, .resuming: return .paused
        case .finishing: return .finishing
        case .completed: return .completed
        case .failed: return .failed
        }
    }

    private func mapControls(_ state: RideState, showsFinishConfirmation: Bool) -> RideControlsState {
        switch state {
        case .idle:
            return .idle
        case .preparing:
            return .transitional
        case .ready:
            return .ready
        case .starting:
            return .transitional
        case .active:
            return RideControlsState(
                primaryAction: .pause,
                secondaryAction: .finish,
                primaryEnabled: true,
                secondaryEnabled: true,
                showsFinishConfirmation: showsFinishConfirmation
            )
        case .pausing, .resuming:
            return .transitional
        case .paused:
            return RideControlsState(
                primaryAction: .resume,
                secondaryAction: .finish,
                primaryEnabled: true,
                secondaryEnabled: true,
                showsFinishConfirmation: showsFinishConfirmation
            )
        case .finishing:
            return .transitional
        case .completed:
            return .completed
        case .failed:
            return .failed
        }
    }

    private func isTransitional(_ state: RideState) -> Bool {
        switch state {
        case .preparing, .starting, .pausing, .resuming, .finishing:
            return true
        default:
            return false
        }
    }

    private func mapTitle(_ phase: RidePhaseViewState) -> String {
        switch phase {
        case .idle: return "Ready to Ride"
        case .preparing: return "Preparing Ride..."
        case .ready: return "Ready"
        case .active: return "Ride Active"
        case .paused: return "Ride Paused"
        case .finishing: return "Saving Ride..."
        case .completed: return "Ride Completed"
        case .failed: return "Ride Error"
        }
    }

    private func mapStatusMessage(_ snapshot: RideSnapshot) -> String? {
        if let failure = snapshot.activeFailure {
            switch failure {
            case .locationPermissionRequired, .locationPermissionDenied:
                return "Location access required to track ride."
            case .workoutAuthorizationDenied, .workoutPreparationFailed:
                return "HealthKit workout access required."
            case .locationUnavailable:
                return "GPS location unavailable."
            case .workoutStartFailed, .workoutPauseFailed, .workoutResumeFailed, .workoutFinishFailed:
                return "Workout tracking error."
            case .invalidStateTransition:
                return "Invalid ride state transition."
            case .unexpected:
                return "An unexpected error occurred."
            }
        }
        return nil
    }

    private func mapWarning(_ snapshot: RideSnapshot) -> BannerViewState? {
        if !snapshot.degradations.isEmpty {
            return BannerViewState(
                id: .init(rawValue: "ride-degradation"),
                severity: .warning,
                title: "Degraded Sensor Accuracy",
                message: "Some sensor telemetry is temporarily unavailable."
            )
        }
        return nil
    }
}
