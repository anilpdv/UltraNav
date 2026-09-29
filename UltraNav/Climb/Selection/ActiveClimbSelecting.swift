import Foundation

/// Result of evaluating climbs against the current route position.
struct ClimbSelectionResult: Equatable, Sendable {
    let activeClimb: Climb?
    let upcomingClimb: Climb?
    let distanceToUpcomingClimbMeters: Double?
    let completedClimbIDs: Set<Climb.ID>
    let newlyStartedClimb: Climb?
    let newlyCompletedClimb: Climb?
    let newlySkippedClimbs: [Climb]
    let approachingClimb: Climb?
    let approachingDistanceMeters: Double?

    init(
        activeClimb: Climb?,
        upcomingClimb: Climb?,
        distanceToUpcomingClimbMeters: Double?,
        completedClimbIDs: Set<Climb.ID>,
        newlyStartedClimb: Climb? = nil,
        newlyCompletedClimb: Climb? = nil,
        newlySkippedClimbs: [Climb] = [],
        approachingClimb: Climb? = nil,
        approachingDistanceMeters: Double? = nil
    ) {
        self.activeClimb = activeClimb
        self.upcomingClimb = upcomingClimb
        self.distanceToUpcomingClimbMeters = distanceToUpcomingClimbMeters
        self.completedClimbIDs = completedClimbIDs
        self.newlyStartedClimb = newlyStartedClimb
        self.newlyCompletedClimb = newlyCompletedClimb
        self.newlySkippedClimbs = newlySkippedClimbs
        self.approachingClimb = approachingClimb
        self.approachingDistanceMeters = approachingDistanceMeters
    }
}

/// Protocol for selecting active/upcoming climbs and advancing completion status.
protocol ActiveClimbSelecting: Sendable {
    func select(
        climbs: [Climb],
        routeDistanceMeters: Double,
        previousActiveClimbID: Climb.ID?,
        completedClimbIDs: Set<Climb.ID>,
        approachThresholdMeters: Double
    ) -> ClimbSelectionResult
}
