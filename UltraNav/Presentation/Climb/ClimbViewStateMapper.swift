import Foundation

public struct ClimbViewStateMapper: Sendable {
    private let distanceFormatter: any DistanceFormatting
    private let elevationFormatter: any ElevationFormatting
    private let gradientFormatter: any GradientFormatting

    public init(
        distanceFormatter: any DistanceFormatting = StandardDistanceFormatter(),
        elevationFormatter: any ElevationFormatting = StandardElevationFormatter(),
        gradientFormatter: any GradientFormatting = StandardGradientFormatter()
    ) {
        self.distanceFormatter = distanceFormatter
        self.elevationFormatter = elevationFormatter
        self.gradientFormatter = gradientFormatter
    }

    func map(
        snapshot: ClimbSnapshot,
        preferences: UnitPreferences = .default
    ) -> ClimbViewState {
        let phase = mapPhase(snapshot)
        let categoryText = snapshot.activeClimb?.category.displayName
        let distRemaining = snapshot.distanceRemainingInActiveClimb.map {
            distanceFormatter.formatDistance(meters: $0, preferences: preferences)
        }
        let elevRemaining: MetricDisplayValue?
        if let progress = snapshot.activeClimbProgress {
            elevRemaining = elevationFormatter.formatElevation(meters: progress.elevationRemainingMeters, preferences: preferences)
        } else {
            elevRemaining = nil
        }
        let currentGrad = gradientFormatter.formatGradient(ratio: snapshot.currentGradePercent / 100.0)
        let progress = snapshot.activeClimbProgress?.fractionCompleted ?? 0.0
        let profile = mapProfile(snapshot)
        let message = mapMessage(phase, snapshot: snapshot)

        return ClimbViewState(
            phase: phase,
            categoryText: categoryText,
            distanceRemaining: distRemaining,
            elevationRemaining: elevRemaining,
            currentGradient: currentGrad,
            progress: progress,
            profile: profile,
            message: message
        )
    }

    private func mapPhase(_ snapshot: ClimbSnapshot) -> ClimbPhaseViewState {
        switch snapshot.state {
        case .unloaded:
            return .unavailable
        case .analyzing:
            return .analyzing
        case .ready:
            if snapshot.hasActiveClimb {
                return .active
            } else if let dist = snapshot.distanceToUpcomingClimbMeters, dist <= 500 {
                return .approaching
            } else if snapshot.upcomingClimb != nil {
                return .upcoming
            }
            return .noClimbs
        case .activeClimb:
            return .active
        case .completedAllClimbs:
            return .completed
        case .failed:
            return .failed
        }
    }

    private func mapProfile(_ snapshot: ClimbSnapshot) -> ClimbProfileViewState? {
        guard let climb = snapshot.activeClimb ?? snapshot.upcomingClimb else {
            return nil
        }

        let slices = climb.gradientSlices
        guard !slices.isEmpty else { return nil }

        let totalLen = climb.lengthMeters > 0 ? climb.lengthMeters : 1.0
        let elevSpan = max(1.0, climb.elevationGainMeters)

        var points: [ClimbProfilePointViewState] = []
        for slice in slices {
            let normDist = min(1.0, max(0.0, (slice.endDistanceMeters - climb.startDistanceMeters) / totalLen))
            let normElev = min(1.0, max(0.0, (slice.endElevationMeters - climb.startElevationMeters) / elevSpan))
            let band = mapGradientBand(slice.gradientRatio)
            points.append(ClimbProfilePointViewState(
                normalizedDistance: normDist,
                normalizedElevation: normElev,
                gradientBand: band
            ))
        }

        let progress = snapshot.activeClimbProgress?.fractionCompleted ?? 0.0
        let summitText = "\(Int(climb.summitElevationMeters.rounded()))m"
        let summary = "Climb profile: \(climb.category.displayName), length \(Int(climb.lengthMeters))m, summit \(summitText)."

        return ClimbProfileViewState(
            points: points,
            currentProgress: progress,
            summitLabel: summitText,
            accessibilitySummary: summary
        )
    }

    private func mapGradientBand(_ ratio: Double) -> GradientBandViewState {
        if ratio < 0 {
            return .descent
        } else if ratio < 0.03 {
            return .easy
        } else if ratio < 0.06 {
            return .moderate
        } else if ratio < 0.09 {
            return .hard
        } else {
            return .severe
        }
    }

    private func mapMessage(_ phase: ClimbPhaseViewState, snapshot: ClimbSnapshot) -> String? {
        switch phase {
        case .unavailable:
            return "No route active."
        case .analyzing:
            return "Analyzing elevation profile..."
        case .noClimbs:
            return "No climbs detected on route."
        case .upcoming:
            if let dist = snapshot.distanceToUpcomingClimbMeters {
                return "Upcoming climb in \(Int(dist))m."
            }
            return "Upcoming climb on route."
        case .approaching:
            return "Climb approaching!"
        case .active:
            if let climb = snapshot.activeClimb {
                return "Climb \(climb.climbIndex) of \(climb.totalClimbs)"
            }
            return "Climbing"
        case .completed:
            return "All climbs completed!"
        case .failed:
            return "Failed to analyze elevation profile."
        }
    }
}
