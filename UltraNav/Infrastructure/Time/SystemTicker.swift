import Foundation

/// Production ticker emitting Date values using Swift concurrency sleeping.
final class SystemTicker: TickProviding, @unchecked Sendable {
    private let clock: any ClockProviding

    init(clock: any ClockProviding = SystemClock()) {
        self.clock = clock
    }

    func ticks(every interval: TimeInterval) -> AsyncStream<Date> {
        let clock = self.clock
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task {
                let nanoseconds = UInt64(max(0.01, interval) * 1_000_000_000)
                while !Task.isCancelled {
                    do {
                        try await Task.sleep(nanoseconds: nanoseconds)
                    } catch {
                        break
                    }
                    if Task.isCancelled { break }
                    continuation.yield(clock.now)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
