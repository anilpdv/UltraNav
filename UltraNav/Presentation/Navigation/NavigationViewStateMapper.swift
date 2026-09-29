import Foundation

public struct NavigationViewStateMapper: Sendable {
    private let distanceFormatter: any DistanceFormatting
    private let mapMapper: RouteMapViewStateMapper

    public init(
        distanceFormatter: any DistanceFormatting = StandardDistanceFormatter(),
        mapMapper: RouteMapViewStateMapper = RouteMapViewStateMapper()
    ) {
        self.distanceFormatter = distanceFormatter
        self.mapMapper = mapMapper
    }

    func map(
        snapshot: NavigationSnapshot,
        preferences: UnitPreferences = .default
    ) -> NavigationViewState {
        let phase = mapPhase(snapshot.state, offRouteStatus: snapshot.offRouteStatus)
        let distanceRemaining = distanceFormatter.formatDistance(meters: snapshot.distanceRemainingMeters, preferences: preferences)
        let nextCue = snapshot.nextCue.map { mapCue($0, preferences: preferences) }
        let banner = mapBanner(snapshot, preferences: preferences)
        let mapState = mapMapper.map(navigationSnapshot: snapshot)
        let progressText = String(format: "%.0f%%", snapshot.routeProgress * 100.0)

        let canStart = snapshot.state == .ready
        let canStop = snapshot.state == .navigating || snapshot.state == .suspectedOffRoute || snapshot.state == .offRoute || snapshot.state == .rejoining
        let canClear = snapshot.state == .ready || snapshot.state == .finished || (snapshot.state != .navigating && snapshot.routeID != nil)

        return NavigationViewState(
            phase: phase,
            routeName: snapshot.routeName,
            progressText: progressText,
            distanceRemaining: distanceRemaining,
            nextCue: nextCue,
            banner: banner,
            map: mapState,
            canStart: canStart,
            canStop: canStop,
            canClear: canClear
        )
    }

    private func mapPhase(_ state: NavigationState, offRouteStatus: OffRouteStatus) -> NavigationPhaseViewState {
        switch state {
        case .inactive:
            return .inactive
        case .loading:
            return .loading
        case .ready:
            return .ready
        case .starting, .navigating, .rejoining:
            if offRouteStatus == .offRoute {
                return .offRoute
            }
            return .navigating
        case .suspectedOffRoute, .offRoute:
            return .offRoute
        case .finishing, .finished:
            return .finished
        case .failed:
            return .failed
        }
    }

    private func mapCue(_ cue: NavigationCue, preferences: UnitPreferences) -> CueViewState {
        let maneuver = mapManeuver(cue.maneuver)
        let distance = distanceFormatter.formatDistance(meters: cue.routeDistanceMeters, preferences: preferences)
        let instruction = cue.instruction ?? "Continue"
        return CueViewState(
            maneuver: maneuver,
            instruction: instruction,
            distance: distance,
            accessibilityLabel: "\(instruction), in \(distance.accessibilityValue)"
        )
    }

    private func mapManeuver(_ maneuver: NavigationManeuver) -> ManeuverViewState {
        switch maneuver {
        case .continueStraight: return .straight
        case .slightLeft: return .slightLeft
        case .left: return .left
        case .sharpLeft: return .sharpLeft
        case .slightRight: return .slightRight
        case .right: return .right
        case .sharpRight: return .sharpRight
        case .uTurn: return .uTurn
        case .arrive: return .arrive
        case .unknown: return .unknown
        }
    }

    private func mapBanner(_ snapshot: NavigationSnapshot, preferences: UnitPreferences) -> NavigationBannerState? {
        if snapshot.offRouteStatus == .offRoute {
            let dist = snapshot.crossTrackDistanceMeters.map {
                distanceFormatter.formatDistance(meters: $0, preferences: preferences)
            }
            return .offRoute(distance: dist)
        } else if snapshot.offRouteStatus == .suspected {
            return .possibleDeviation
        }

        switch snapshot.state {
        case .loading:
            return .calculating
        case .rejoining:
            return .rejoining
        case .finished:
            return .routeCompleted
        case .failed(let failure, _):
            return .error(message: failureMessage(failure))
        default:
            return nil
        }
    }

    private func failureMessage(_ failure: NavigationFailure) -> String {
        switch failure {
        case .routeUnavailable: return "Failed to load route."
        case .invalidRoute: return "Route format is invalid."
        case .locationUnavailable: return "Location GPS unavailable."
        case .calculationFailed: return "Turn instruction calculation error."
        case .unexpected: return "Unexpected navigation error."
        }
    }
}
