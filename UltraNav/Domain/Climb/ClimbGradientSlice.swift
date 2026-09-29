import Foundation

/// A discrete sub-segment of a climb having a constant or average gradient.
struct ClimbGradientSlice: Equatable, Sendable, Codable {
    let startDistanceMeters: Double
    let endDistanceMeters: Double
    let startElevationMeters: Double
    let endElevationMeters: Double
    /// Gradient expressed as ratio (e.g. 0.08 is 8% grade).
    let gradientRatio: Double

    var lengthMeters: Double {
        max(0, endDistanceMeters - startDistanceMeters)
    }

    var elevationDeltaMeters: Double {
        endElevationMeters - startElevationMeters
    }

    var gradientPercent: Double {
        gradientRatio * 100.0
    }

    init(
        startDistanceMeters: Double,
        endDistanceMeters: Double,
        startElevationMeters: Double,
        endElevationMeters: Double,
        gradientRatio: Double
    ) {
        precondition(endDistanceMeters >= startDistanceMeters, "endDistanceMeters must be >= startDistanceMeters")
        self.startDistanceMeters = startDistanceMeters
        self.endDistanceMeters = endDistanceMeters
        self.startElevationMeters = startElevationMeters
        self.endElevationMeters = endElevationMeters
        self.gradientRatio = gradientRatio
    }
}
