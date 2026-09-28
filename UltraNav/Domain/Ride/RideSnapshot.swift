import Foundation

struct RideSnapshot: Equatable, Sendable {
    let state: RideState

    /// Total duration since ride start, excluding no period unless
    /// explicitly defined by the engine.
    let elapsedTimeSeconds: TimeInterval

    /// Time considered moving by the ride engine.
    let movingTimeSeconds: TimeInterval

    let metrics: RideMetrics

    static let initial = RideSnapshot(
        state: .idle,
        elapsedTimeSeconds: 0,
        movingTimeSeconds: 0,
        metrics: .empty
    )
}
