import Foundation
@testable import UltraNav

/// Standardized climb domain and snapshot fixtures.
enum ClimbFixture {
    static func climb(
        id: String = "climb-001",
        startDistanceMeters: Double = 1000.0,
        endDistanceMeters: Double = 3000.0,
        startElevationMeters: Double = 600.0,
        endElevationMeters: Double = 850.0,
        category: ClimbCategory = .category3,
        averageGradientPercent: Double = 12.5
    ) -> Climb {
        let gradRatio = averageGradientPercent / 100.0
        return Climb(
            id: Climb.ID(rawValue: id),
            routeID: TestIDs.routeAlpha,
            climbIndex: 0,
            totalClimbs: 1,
            startIndex: 0,
            endIndex: 10,
            startDistanceMeters: startDistanceMeters,
            endDistanceMeters: endDistanceMeters,
            startElevationMeters: startElevationMeters,
            summitElevationMeters: endElevationMeters,
            elevationGainMeters: max(0, endElevationMeters - startElevationMeters),
            averageGradientRatio: gradRatio,
            maximumGradientRatio: gradRatio * 1.2,
            category: category,
            gradientSlices: [
                ClimbGradientSlice(
                    startDistanceMeters: startDistanceMeters,
                    endDistanceMeters: endDistanceMeters,
                    startElevationMeters: startElevationMeters,
                    endElevationMeters: endElevationMeters,
                    gradientRatio: gradRatio
                )
            ]
        )
    }

    static func progress(
        climb: Climb = climb(),
        currentDistanceAlongRouteMeters: Double = 1500.0
    ) -> ClimbProgress {
        ClimbProgress(
            climb: climb,
            distanceIntoClimbMeters: 500.0,
            distanceRemainingMeters: 1500.0,
            elevationRemainingMeters: 187.5,
            currentElevationMeters: 662.5,
            currentGradientRatio: 0.125,
            fractionCompleted: 0.25
        )
    }

    static func snapshot(
        activeClimb: Climb? = climb(),
        progress: ClimbProgress? = progress(),
        totalClimbsCount: Int = 1,
        completedClimbsCount: Int = 0
    ) -> ClimbSnapshot {
        ClimbSnapshot(
            state: activeClimb != nil ? .activeClimb : .ready,
            routeID: TestIDs.routeAlpha,
            climbs: activeClimb.map { [$0] } ?? [],
            activeClimb: activeClimb,
            activeClimbProgress: progress,
            upcomingClimb: nil,
            distanceToUpcomingClimbMeters: nil,
            completedClimbIDs: [],
            totalElevationGainMeters: 250.0,
            currentElevationMeters: 662.5,
            currentGradePercent: 12.5,
            vamMetersPerHour: 800.0,
            failure: nil,
            timestamp: TestDates.rideStart
        )
    }
}
