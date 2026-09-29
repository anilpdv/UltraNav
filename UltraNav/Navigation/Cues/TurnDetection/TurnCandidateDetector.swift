import Foundation

/// Represents an unmerged turn candidate extracted from route bearing variations.
struct TurnCandidate: Equatable, Sendable {
    let distanceAlongRouteMeters: Double
    let coordinate: Coordinate
    let turnAngleDegrees: Double
    let maneuver: NavigationManeuver

    init(
        distanceAlongRouteMeters: Double,
        coordinate: Coordinate,
        turnAngleDegrees: Double,
        maneuver: NavigationManeuver
    ) {
        self.distanceAlongRouteMeters = distanceAlongRouteMeters
        self.coordinate = coordinate
        self.turnAngleDegrees = turnAngleDegrees
        self.maneuver = maneuver
    }
}

/// Configuration parameters for turn candidate detection.
struct TurnDetectionConfiguration: Equatable, Sendable {
    var minimumTurnAngleDegrees: Double
    var windowDistanceMeters: Double
    var stepDistanceMeters: Double
    var edgeBufferMeters: Double

    init(
        minimumTurnAngleDegrees: Double = 20.0,
        windowDistanceMeters: Double = 25.0,
        stepDistanceMeters: Double = 5.0,
        edgeBufferMeters: Double = 15.0
    ) {
        self.minimumTurnAngleDegrees = minimumTurnAngleDegrees
        self.windowDistanceMeters = windowDistanceMeters
        self.stepDistanceMeters = stepDistanceMeters
        self.edgeBufferMeters = edgeBufferMeters
    }
}

/// Scans a route bearing profile to detect significant directional deviation candidates.
struct TurnCandidateDetector: Sendable {
    let configuration: TurnDetectionConfiguration

    init(configuration: TurnDetectionConfiguration = TurnDetectionConfiguration()) {
        self.configuration = configuration
    }

    /// Detects turn candidates across the entire route.
    func detectCandidates(profile: RouteBearingProfile) -> [TurnCandidate] {
        guard profile.totalDistanceMeters >= (configuration.edgeBufferMeters * 2.0) else {
            return []
        }

        var candidates: [TurnCandidate] = []
        var d = configuration.edgeBufferMeters
        let maxDist = profile.totalDistanceMeters - configuration.edgeBufferMeters

        var candidateInterval: [(distance: Double, angle: Double)] = []

        while d <= maxDist {
            if let angle = profile.turnAngle(at: d, windowMeters: configuration.windowDistanceMeters) {
                if abs(angle) >= configuration.minimumTurnAngleDegrees {
                    candidateInterval.append((distance: d, angle: angle))
                } else if !candidateInterval.isEmpty {
                    // Closed out an active turn zone -> find peak
                    if let peak = selectPeak(interval: candidateInterval, profile: profile) {
                        candidates.append(peak)
                    }
                    candidateInterval.removeAll()
                }
            }
            d += configuration.stepDistanceMeters
        }

        if !candidateInterval.isEmpty {
            if let peak = selectPeak(interval: candidateInterval, profile: profile) {
                candidates.append(peak)
            }
        }

        return candidates
    }

    private func selectPeak(
        interval: [(distance: Double, angle: Double)],
        profile: RouteBearingProfile
    ) -> TurnCandidate? {
        guard let maxPoint = interval.max(by: { abs($0.angle) < abs($1.angle) }) else {
            return nil
        }
        guard let coord = profile.coordinate(at: maxPoint.distance) else {
            return nil
        }

        let maneuver = ManeuverClassifier.classify(turnAngleDegrees: maxPoint.angle)
        guard maneuver != .continueStraight else { return nil }

        return TurnCandidate(
            distanceAlongRouteMeters: maxPoint.distance,
            coordinate: coord,
            turnAngleDegrees: maxPoint.angle,
            maneuver: maneuver
        )
    }
}
