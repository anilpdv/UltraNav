import Foundation
@testable import UltraNav

struct ClimbFactory {
    static func makeClimb(
        routeID: UUID = UUID(),
        climbIndex: Int = 1,
        totalClimbs: Int = 1,
        startIndex: Int = 0,
        endIndex: Int = 10,
        startDistanceMeters: Double = 1000,
        endDistanceMeters: Double = 3000,
        startElevationMeters: Double = 100,
        summitElevationMeters: Double = 300,
        elevationGainMeters: Double = 200,
        averageGradientRatio: Double = 0.10,
        maximumGradientRatio: Double = 0.15,
        category: ClimbCategory = .category3,
        gradientSlices: [ClimbGradientSlice] = []
    ) -> Climb {
        let slices: [ClimbGradientSlice]
        if gradientSlices.isEmpty {
            slices = [
                ClimbGradientSlice(
                    startDistanceMeters: startDistanceMeters,
                    endDistanceMeters: endDistanceMeters,
                    startElevationMeters: startElevationMeters,
                    endElevationMeters: summitElevationMeters,
                    gradientRatio: averageGradientRatio
                )
            ]
        } else {
            slices = gradientSlices
        }

        return Climb(
            id: Climb.ID(routeID: routeID, climbIndex: climbIndex),
            routeID: routeID,
            climbIndex: climbIndex,
            totalClimbs: totalClimbs,
            startIndex: startIndex,
            endIndex: endIndex,
            startDistanceMeters: startDistanceMeters,
            endDistanceMeters: endDistanceMeters,
            startElevationMeters: startElevationMeters,
            summitElevationMeters: summitElevationMeters,
            elevationGainMeters: elevationGainMeters,
            averageGradientRatio: averageGradientRatio,
            maximumGradientRatio: maximumGradientRatio,
            category: category,
            gradientSlices: slices
        )
    }

    static func makeCandidate(
        startIndex: Int = 0,
        endIndex: Int = 10,
        startDistanceMeters: Double = 1000,
        endDistanceMeters: Double = 3000,
        startElevationMeters: Double = 100,
        endElevationMeters: Double = 300,
        summitElevationMeters: Double = 300,
        netElevationGainMeters: Double = 200,
        totalElevationGainMeters: Double = 200,
        averageGradientRatio: Double = 0.10,
        maximumGradientRatio: Double = 0.15,
        slices: [ClimbGradientSlice] = []
    ) -> ClimbCandidate {
        ClimbCandidate(
            startIndex: startIndex,
            endIndex: endIndex,
            startDistanceMeters: startDistanceMeters,
            endDistanceMeters: endDistanceMeters,
            startElevationMeters: startElevationMeters,
            endElevationMeters: endElevationMeters,
            summitElevationMeters: summitElevationMeters,
            netElevationGainMeters: netElevationGainMeters,
            totalElevationGainMeters: totalElevationGainMeters,
            averageGradientRatio: averageGradientRatio,
            maximumGradientRatio: maximumGradientRatio,
            slices: slices
        )
    }
}
