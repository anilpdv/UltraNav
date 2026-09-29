import Foundation

struct SystemMonotonicClock: MonotonicClockProviding, Sendable {
    var now: MonotonicInstant {
        let value = DispatchTime.now().uptimeNanoseconds
        return MonotonicInstant(nanoseconds: value)
    }

    func duration(from start: MonotonicInstant, to end: MonotonicInstant) -> Duration {
        guard end.nanoseconds >= start.nanoseconds else {
            return .zero
        }
        let difference = end.nanoseconds - start.nanoseconds
        let clamped = min(difference, UInt64(Int64.max))
        return .nanoseconds(Int64(clamped))
    }
}
