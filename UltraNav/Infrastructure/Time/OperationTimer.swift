import Foundation

struct TimedOperationResult<Value: Sendable>: Sendable {
    let value: Value
    let duration: Duration
}

struct OperationTimer: Sendable {
    private let clock: any MonotonicClockProviding

    init(clock: any MonotonicClockProviding = SystemMonotonicClock()) {
        self.clock = clock
    }

    func measure<T: Sendable>(
        _ body: @Sendable () async throws -> T
    ) async throws -> TimedOperationResult<T> {
        let start = clock.now
        let value = try await body()
        let end = clock.now
        let duration = clock.duration(from: start, to: end)
        return TimedOperationResult(value: value, duration: duration)
    }

    func measureNonThrowing<T: Sendable>(
        _ body: @Sendable () async -> T
    ) async -> TimedOperationResult<T> {
        let start = clock.now
        let value = await body()
        let end = clock.now
        let duration = clock.duration(from: start, to: end)
        return TimedOperationResult(value: value, duration: duration)
    }
}
