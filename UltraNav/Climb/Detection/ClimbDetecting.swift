import Foundation

/// Protocol for detecting climb candidates from an ElevationProfile.
protocol ClimbDetecting: Sendable {
    func detectClimbs(in profile: ElevationProfile) throws -> [ClimbCandidate]
}
