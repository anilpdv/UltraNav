import Foundation

/// Standard implementation of ClimbProgressCalculating.
struct StandardClimbProgressCalculator: ClimbProgressCalculating {
    init() {}

    func calculateProgress(
        for climb: Climb,
        at routeDistanceMeters: Double,
        currentElevationMeters: Double?,
        quality: ClimbProgressQuality
    ) -> ClimbProgress {
        let length = climb.lengthMeters
        let distanceIntoClimb = max(0, min(length, routeDistanceMeters - climb.startDistanceMeters))
        let distanceRemaining = max(0, climb.endDistanceMeters - routeDistanceMeters)
        let fraction = length > 0 ? min(1.0, max(0.0, distanceIntoClimb / length)) : 1.0

        let elevationRemaining: Double
        if let currentElevation = currentElevationMeters {
            elevationRemaining = max(0, climb.summitElevationMeters - currentElevation)
        } else {
            elevationRemaining = max(0, climb.elevationGainMeters * (1.0 - fraction))
        }

        // Find current gradient slice
        let currentSlice = climb.gradientSlices.first { slice in
            routeDistanceMeters >= slice.startDistanceMeters && routeDistanceMeters <= slice.endDistanceMeters
        }
        let gradientRatio = currentSlice?.gradientRatio ?? climb.averageGradientRatio

        return ClimbProgress(
            climb: climb,
            distanceIntoClimbMeters: distanceIntoClimb,
            distanceRemainingMeters: distanceRemaining,
            elevationRemainingMeters: elevationRemaining,
            currentElevationMeters: currentElevationMeters,
            currentGradientRatio: gradientRatio,
            fractionCompleted: fraction,
            estimatedTimeToSummitSeconds: nil,
            quality: quality
        )
    }
}
