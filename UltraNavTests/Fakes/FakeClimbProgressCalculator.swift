import Foundation
@testable import UltraNav

final class FakeClimbProgressCalculator: ClimbProgressCalculating, @unchecked Sendable {
    var stubbedProgress: ClimbProgress?
    var calculateCallCount = 0

    func calculateProgress(
        for climb: Climb,
        at routeDistanceMeters: Double,
        currentElevationMeters: Double?,
        quality: ClimbProgressQuality
    ) -> ClimbProgress {
        calculateCallCount += 1
        if let stubbed = stubbedProgress {
            return stubbed
        }
        let length = climb.lengthMeters
        let into = max(0, min(length, routeDistanceMeters - climb.startDistanceMeters))
        let remaining = max(0, climb.endDistanceMeters - routeDistanceMeters)
        let fraction = length > 0 ? into / length : 1.0

        return ClimbProgress(
            climb: climb,
            distanceIntoClimbMeters: into,
            distanceRemainingMeters: remaining,
            elevationRemainingMeters: max(0, climb.elevationGainMeters * (1 - fraction)),
            currentElevationMeters: currentElevationMeters,
            currentGradientRatio: climb.averageGradientRatio,
            fractionCompleted: fraction,
            quality: quality
        )
    }
}
