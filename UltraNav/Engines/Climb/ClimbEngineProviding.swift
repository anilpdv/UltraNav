import Foundation

/// Public interface for the ClimbEngine boundary.
protocol ClimbEngineProviding: AnyObject, Sendable {
    /// Synchronously returns the most recent climb snapshot.
    @MainActor var currentSnapshot: ClimbSnapshot { get }

    /// Asynchronous stream of continuous climb snapshots.
    @MainActor var snapshots: AsyncStream<ClimbSnapshot> { get }

    /// Asynchronous stream of discrete climb milestone notifications.
    @MainActor var notifications: AsyncStream<ClimbNotification> { get }

    /// Sends a command to the climb engine.
    @MainActor func send(_ command: ClimbEngineCommand) async
}
