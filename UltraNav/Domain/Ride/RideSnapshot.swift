import Foundation

struct RideSnapshot: Equatable, Sendable {
    let state: RideState

    let startedAt: Date?
    let endedAt: Date?

    /// Total duration since ride start, excluding no period unless
    /// explicitly defined by the engine.
    let elapsedTimeSeconds: TimeInterval

    /// Time considered moving by the ride engine.
    let movingTimeSeconds: TimeInterval

    let metrics: RideMetrics

    let locationStatus: RideLocationStatus
    let workoutStatus: RideWorkoutStatus
    let sensorStatus: RideSensorStatus
    let degradations: RideDegradation
    let activeFailure: RideFailure?

    init(
        state: RideState,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        elapsedTimeSeconds: TimeInterval = 0,
        movingTimeSeconds: TimeInterval = 0,
        metrics: RideMetrics = .empty,
        locationStatus: RideLocationStatus = .unavailable,
        workoutStatus: RideWorkoutStatus = .unavailable,
        sensorStatus: RideSensorStatus = .empty,
        degradations: RideDegradation = [],
        activeFailure: RideFailure? = nil
    ) {
        self.state = state
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.movingTimeSeconds = movingTimeSeconds
        self.metrics = metrics
        self.locationStatus = locationStatus
        self.workoutStatus = workoutStatus
        self.sensorStatus = sensorStatus
        self.degradations = degradations
        self.activeFailure = activeFailure
    }

    static let initial = RideSnapshot(
        state: .idle,
        startedAt: nil,
        endedAt: nil,
        elapsedTimeSeconds: 0,
        movingTimeSeconds: 0,
        metrics: .empty,
        locationStatus: .unavailable,
        workoutStatus: .unavailable,
        sensorStatus: .empty,
        degradations: [],
        activeFailure: nil
    )
}
