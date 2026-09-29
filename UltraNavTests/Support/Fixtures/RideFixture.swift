import Foundation
@testable import UltraNav

/// Standardized ride snapshot and state fixtures.
enum RideFixture {
    static func snapshot(
        state: RideState = .active,
        workoutStatus: RideWorkoutStatus = .active,
        locationStatus: RideLocationStatus = .active,
        elapsedTimeSeconds: TimeInterval = 120.0,
        movingTimeSeconds: TimeInterval = 100.0,
        startedAt: Date? = TestDates.rideStart
    ) -> RideSnapshot {
        RideSnapshot(
            state: state,
            startedAt: startedAt,
            endedAt: nil,
            elapsedTimeSeconds: elapsedTimeSeconds,
            movingTimeSeconds: movingTimeSeconds,
            metrics: .empty,
            locationStatus: locationStatus,
            workoutStatus: workoutStatus,
            sensorStatus: .empty,
            degradations: [],
            activeFailure: nil
        )
    }

    static func idleSnapshot() -> RideSnapshot {
        .initial
    }

    static func pausedSnapshot() -> RideSnapshot {
        snapshot(state: .paused, workoutStatus: .paused, locationStatus: .ready, elapsedTimeSeconds: 60, movingTimeSeconds: 30)
    }

    static func completedSnapshot() -> RideSnapshot {
        RideSnapshot(
            state: .completed,
            startedAt: TestDates.rideStart,
            endedAt: TestDates.oneHourLater,
            elapsedTimeSeconds: 3600,
            movingTimeSeconds: 3400,
            metrics: .empty,
            locationStatus: .ready,
            workoutStatus: .ended,
            sensorStatus: .empty,
            degradations: [],
            activeFailure: nil
        )
    }
}
