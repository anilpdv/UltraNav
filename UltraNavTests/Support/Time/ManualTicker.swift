import Foundation

/// Manually triggered ticker that emits events without relying on Timer or background threads.
actor ManualTicker {
    nonisolated let ticks: AsyncStream<Date>
    private let continuation: AsyncStream<Date>.Continuation
    private(set) var tickCount = 0

    init() {
        let pair = AsyncStream.makeStream(of: Date.self)
        self.ticks = pair.stream
        self.continuation = pair.continuation
    }

    /// Emits a single tick with a given timestamp.
    func tick(at date: Date = Date()) {
        tickCount += 1
        continuation.yield(date)
    }

    /// Emits multiple ticks sequentially.
    func tick(count: Int, startingAt startDate: Date = Date(), interval: TimeInterval = 1.0) {
        var current = startDate
        for _ in 0..<count {
            tick(at: current)
            current = current.addingTimeInterval(interval)
        }
    }

    /// Stops the ticker stream cleanly.
    func stop() {
        continuation.finish()
    }
}
