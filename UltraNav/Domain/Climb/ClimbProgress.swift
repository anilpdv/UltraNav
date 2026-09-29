import Foundation

/// Value type expressing real-time progress through an active climb.
struct ClimbProgress: Equatable, Sendable, Codable {
    let climb: Climb
    let distanceIntoClimbMeters: Double
    let distanceRemainingMeters: Double
    let elevationRemainingMeters: Double
    let currentElevationMeters: Double?
    let currentGradientRatio: Double?
    let fractionCompleted: Double
    let estimatedTimeToSummitSeconds: TimeInterval?
    let quality: ClimbProgressQuality

    var distanceIntoClimbPercent: Double {
        fractionCompleted * 100.0
    }

    var currentGradientPercent: Double? {
        currentGradientRatio.map { $0 * 100.0 }
    }

    init(
        climb: Climb,
        distanceIntoClimbMeters: Double,
        distanceRemainingMeters: Double,
        elevationRemainingMeters: Double,
        currentElevationMeters: Double? = nil,
        currentGradientRatio: Double? = nil,
        fractionCompleted: Double,
        estimatedTimeToSummitSeconds: TimeInterval? = nil,
        quality: ClimbProgressQuality = .reliable
    ) {
        self.climb = climb
        self.distanceIntoClimbMeters = distanceIntoClimbMeters
        self.distanceRemainingMeters = distanceRemainingMeters
        self.elevationRemainingMeters = elevationRemainingMeters
        self.currentElevationMeters = currentElevationMeters
        self.currentGradientRatio = currentGradientRatio
        self.fractionCompleted = min(1.0, max(0.0, fractionCompleted))
        self.estimatedTimeToSummitSeconds = estimatedTimeToSummitSeconds
        self.quality = quality
    }
}
