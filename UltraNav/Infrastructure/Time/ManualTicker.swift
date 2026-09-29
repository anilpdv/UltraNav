import Foundation

/// Test double ticker that allows deterministic, manual tick triggering.
final class ManualTicker: TickProviding, @unchecked Sendable {
    private let channel = AsyncEventChannel<Date>()

    init() {}

    func ticks(every interval: TimeInterval) -> AsyncStream<Date> {
        channel.makeStream()
    }

    /// Explicitly fires a tick with the provided date.
    func tick(date: Date = Date()) {
        channel.send(date)
    }

    /// Finishes all active tick streams.
    func finish() {
        channel.finish()
    }
}
