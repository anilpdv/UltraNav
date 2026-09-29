import Foundation

/// Specific failure modes encountered during climb analysis or progress tracking.
enum ClimbFailure: Error, Equatable, Sendable, Codable {
    case routeUnavailable
    case noElevationData
    case insufficientElevationData
    case profileConstructionFailed(String)
    case climbDetectionFailed(String)
    case invalidClimb(String)
    case progressCalculationFailed(String)
    case unexpected(String)
}
