import Foundation

/// Protocol providing periodic time tick streams.
protocol TickProviding: Sendable {
    /// Produces a stream of dates emitted at the specified interval.
    func ticks(every interval: TimeInterval) -> AsyncStream<Date>
}
