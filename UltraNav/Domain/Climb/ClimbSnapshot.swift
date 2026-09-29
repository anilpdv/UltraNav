import Foundation

/// Unified immutable output snapshot from ClimbEngine for UI and metric consumers.
struct ClimbSnapshot: Equatable, Sendable, Codable {
    let state: ClimbEngineState
    let routeID: UUID?
    let climbs: [Climb]
    let activeClimb: Climb?
    let activeClimbProgress: ClimbProgress?
    let upcomingClimb: Climb?
    let distanceToUpcomingClimbMeters: Double?
    let completedClimbIDs: Set<Climb.ID>
    let totalElevationGainMeters: Double
    let currentElevationMeters: Double?
    let currentGradePercent: Double
    let vamMetersPerHour: Double
    let failure: ClimbFailure?
    let timestamp: Date

    var hasActiveClimb: Bool {
        activeClimb != nil
    }

    var totalClimbsCount: Int {
        climbs.count
    }

    var completedClimbsCount: Int {
        completedClimbIDs.count
    }

    var distanceRemainingInActiveClimb: Double? {
        activeClimbProgress?.distanceRemainingMeters
    }

    init(
        state: ClimbEngineState = .unloaded,
        routeID: UUID? = nil,
        climbs: [Climb] = [],
        activeClimb: Climb? = nil,
        activeClimbProgress: ClimbProgress? = nil,
        upcomingClimb: Climb? = nil,
        distanceToUpcomingClimbMeters: Double? = nil,
        completedClimbIDs: Set<Climb.ID> = [],
        totalElevationGainMeters: Double = 0,
        currentElevationMeters: Double? = nil,
        currentGradePercent: Double = 0,
        vamMetersPerHour: Double = 0,
        failure: ClimbFailure? = nil,
        timestamp: Date = Date()
    ) {
        self.state = state
        self.routeID = routeID
        self.climbs = climbs
        self.activeClimb = activeClimb
        self.activeClimbProgress = activeClimbProgress
        self.upcomingClimb = upcomingClimb
        self.distanceToUpcomingClimbMeters = distanceToUpcomingClimbMeters
        self.completedClimbIDs = completedClimbIDs
        self.totalElevationGainMeters = totalElevationGainMeters
        self.currentElevationMeters = currentElevationMeters
        self.currentGradePercent = currentGradePercent
        self.vamMetersPerHour = vamMetersPerHour
        self.failure = failure
        self.timestamp = timestamp
    }

    static let empty = ClimbSnapshot()
}
