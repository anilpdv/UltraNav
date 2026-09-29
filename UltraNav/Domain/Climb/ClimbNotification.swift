import Foundation

/// Discrete events emitted by ClimbEngine when significant climb thresholds or transitions occur.
enum ClimbNotification: Equatable, Sendable {
    case routeAnalyzed(totalClimbs: Int)
    case climbApproaching(climb: Climb, distanceMeters: Double)
    case climbStarted(climb: Climb)
    case climbCompleted(climb: Climb)
    case climbSkipped(climb: Climb)
    case allClimbsCompleted
    case analysisFailed(failure: ClimbFailure)
}
