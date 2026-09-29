import Foundation

/// Protocol for computing progress metrics through an active climb.
protocol ClimbProgressCalculating: Sendable {
    func calculateProgress(
        for climb: Climb,
        at routeDistanceMeters: Double,
        currentElevationMeters: Double?,
        quality: ClimbProgressQuality
    ) -> ClimbProgress
}
