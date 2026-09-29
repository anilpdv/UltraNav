import Foundation

/// Standard implementation of ActiveClimbSelecting.
struct StandardActiveClimbSelector: ActiveClimbSelecting {
    init() {}

    func select(
        climbs: [Climb],
        routeDistanceMeters: Double,
        previousActiveClimbID: Climb.ID?,
        completedClimbIDs: Set<Climb.ID>,
        approachThresholdMeters: Double = 500.0
    ) -> ClimbSelectionResult {
        guard !climbs.isEmpty else {
            return ClimbSelectionResult(
                activeClimb: nil,
                upcomingClimb: nil,
                distanceToUpcomingClimbMeters: nil,
                completedClimbIDs: []
            )
        }

        var updatedCompleted = completedClimbIDs
        var newlyCompleted: Climb? = nil
        var newlySkipped: [Climb] = []

        // 1. Check completions & skips for climbs before current distance
        for climb in climbs {
            if routeDistanceMeters >= climb.endDistanceMeters {
                if !updatedCompleted.contains(climb.id) {
                    updatedCompleted.insert(climb.id)
                    if previousActiveClimbID == climb.id {
                        newlyCompleted = climb
                    } else {
                        newlySkipped.append(climb)
                    }
                }
            }
        }

        // 2. Identify active climb
        let activeClimb = climbs.first { climb in
            !updatedCompleted.contains(climb.id) &&
            routeDistanceMeters >= climb.startDistanceMeters &&
            routeDistanceMeters <= climb.endDistanceMeters
        }

        // 3. Identify newly started climb
        var newlyStarted: Climb? = nil
        if let active = activeClimb, active.id != previousActiveClimbID {
            newlyStarted = active
        }

        // 4. Identify upcoming climb
        let upcomingClimb = climbs.first { climb in
            !updatedCompleted.contains(climb.id) &&
            climb.id != activeClimb?.id &&
            climb.startDistanceMeters > routeDistanceMeters
        }

        let distanceToUpcoming: Double?
        let approachingClimb: Climb?
        let approachingDistance: Double?

        if let upcoming = upcomingClimb {
            let dist = max(0, upcoming.startDistanceMeters - routeDistanceMeters)
            distanceToUpcoming = dist
            if dist <= approachThresholdMeters && dist > 0 {
                approachingClimb = upcoming
                approachingDistance = dist
            } else {
                approachingClimb = nil
                approachingDistance = nil
            }
        } else {
            distanceToUpcoming = nil
            approachingClimb = nil
            approachingDistance = nil
        }

        return ClimbSelectionResult(
            activeClimb: activeClimb,
            upcomingClimb: upcomingClimb,
            distanceToUpcomingClimbMeters: distanceToUpcoming,
            completedClimbIDs: updatedCompleted,
            newlyStartedClimb: newlyStarted,
            newlyCompletedClimb: newlyCompleted,
            newlySkippedClimbs: newlySkipped,
            approachingClimb: approachingClimb,
            approachingDistanceMeters: approachingDistance
        )
    }
}
