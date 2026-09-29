import Foundation

/// Intermediate unclassified climb candidate identified during elevation profile scanning.
struct ClimbCandidate: Equatable, Sendable, Codable {
    let startIndex: Int
    let endIndex: Int
    let startDistanceMeters: Double
    let endDistanceMeters: Double
    let startElevationMeters: Double
    let endElevationMeters: Double
    let summitElevationMeters: Double
    let netElevationGainMeters: Double
    let totalElevationGainMeters: Double
    let averageGradientRatio: Double
    let maximumGradientRatio: Double
    let slices: [ClimbGradientSlice]

    var lengthMeters: Double {
        max(0, endDistanceMeters - startDistanceMeters)
    }

    init(
        startIndex: Int,
        endIndex: Int,
        startDistanceMeters: Double,
        endDistanceMeters: Double,
        startElevationMeters: Double,
        endElevationMeters: Double,
        summitElevationMeters: Double,
        netElevationGainMeters: Double,
        totalElevationGainMeters: Double,
        averageGradientRatio: Double,
        maximumGradientRatio: Double,
        slices: [ClimbGradientSlice] = []
    ) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.startDistanceMeters = startDistanceMeters
        self.endDistanceMeters = endDistanceMeters
        self.startElevationMeters = startElevationMeters
        self.endElevationMeters = endElevationMeters
        self.summitElevationMeters = summitElevationMeters
        self.netElevationGainMeters = netElevationGainMeters
        self.totalElevationGainMeters = totalElevationGainMeters
        self.averageGradientRatio = averageGradientRatio
        self.maximumGradientRatio = maximumGradientRatio
        self.slices = slices
    }
}
