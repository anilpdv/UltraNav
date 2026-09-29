import Foundation

/// Pure factory for constructing immutable ClimbSnapshots.
struct ClimbSnapshotBuilder: Sendable {
    init() {}

    func buildSnapshot(
        state: ClimbEngineState,
        routeID: Route.ID?,
        climbs: [Climb],
        activeClimb: Climb?,
        activeClimbProgress: ClimbProgress?,
        upcomingClimb: Climb?,
        distanceToUpcomingClimbMeters: Double?,
        completedClimbIDs: Set<Climb.ID>,
        totalElevationGainMeters: Double,
        currentElevationMeters: Double?,
        currentGradePercent: Double,
        vamMetersPerHour: Double,
        failure: ClimbFailure?,
        timestamp: Date = Date()
    ) -> ClimbSnapshot {
        ClimbSnapshot(
            state: state,
            routeID: routeID,
            climbs: climbs,
            activeClimb: activeClimb,
            activeClimbProgress: activeClimbProgress,
            upcomingClimb: upcomingClimb,
            distanceToUpcomingClimbMeters: distanceToUpcomingClimbMeters,
            completedClimbIDs: completedClimbIDs,
            totalElevationGainMeters: totalElevationGainMeters,
            currentElevationMeters: currentElevationMeters,
            currentGradePercent: currentGradePercent,
            vamMetersPerHour: vamMetersPerHour,
            failure: failure,
            timestamp: timestamp
        )
    }
}
