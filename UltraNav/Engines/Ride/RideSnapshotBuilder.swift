import Foundation

struct RideSnapshotBuilder: Sendable {
    func makeSnapshot(
        state: RideState,
        timing: RideTimingState,
        metrics: RideMetricState,
        locationStatus: RideLocationStatus,
        workoutStatus: RideWorkoutStatus,
        sensorStatus: RideSensorStatus,
        degradations: RideDegradation,
        activeFailure: RideFailure?,
        now: Date
    ) -> RideSnapshot {
        RideSnapshot(
            state: state,
            startedAt: timing.rideStartedAt,
            endedAt: timing.rideEndedAt,
            elapsedTimeSeconds: timing.elapsedTime(at: now),
            movingTimeSeconds: timing.movingTime(at: now),
            metrics: RideMetrics(
                currentSpeedMetersPerSecond: metrics.currentSpeedMetersPerSecond,
                distanceMeters: metrics.distanceMeters,
                heartRateBeatsPerMinute: metrics.heartRateBeatsPerMinute,
                cadenceRevolutionsPerMinute: metrics.cadenceRevolutionsPerMinute,
                powerWatts: metrics.powerWatts,
                altitudeMeters: metrics.altitudeMeters
            ),
            locationStatus: locationStatus,
            workoutStatus: workoutStatus,
            sensorStatus: sensorStatus,
            degradations: degradations,
            activeFailure: activeFailure
        )
    }
}
