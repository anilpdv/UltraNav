import Foundation

/// Unified immutable output snapshot for ClimbPro and elevation profiling.
struct ClimbSnapshot: Equatable, Sendable {
    let currentClimb: ClimbSegment?
    let distanceRemainingInClimb: Double
    let currentElevationMeters: Double?
    let elevationGainedMeters: Double
    let currentGradePercent: Double
    let vamMetersPerHour: Double

    init(
        currentClimb: ClimbSegment? = nil,
        distanceRemainingInClimb: Double = 0,
        currentElevationMeters: Double? = nil,
        elevationGainedMeters: Double = 0,
        currentGradePercent: Double = 0,
        vamMetersPerHour: Double = 0
    ) {
        self.currentClimb = currentClimb
        self.distanceRemainingInClimb = distanceRemainingInClimb
        self.currentElevationMeters = currentElevationMeters
        self.elevationGainedMeters = elevationGainedMeters
        self.currentGradePercent = currentGradePercent
        self.vamMetersPerHour = vamMetersPerHour
    }

    static let empty = ClimbSnapshot()
}
