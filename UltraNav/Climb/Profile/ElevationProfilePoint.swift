import Foundation

/// Individual point in a normalized elevation profile.
struct ElevationProfilePoint: Equatable, Sendable, Codable {
    let distanceMeters: Double
    let elevationMeters: Double
    let originalIndex: Int

    init(distanceMeters: Double, elevationMeters: Double, originalIndex: Int) {
        self.distanceMeters = distanceMeters
        self.elevationMeters = elevationMeters
        self.originalIndex = originalIndex
    }
}
