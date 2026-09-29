import Foundation
@testable import UltraNav

final class TestMonotonicClock: MonotonicClockProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var currentNanoseconds: UInt64

    init(nanoseconds: UInt64 = 0) {
        self.currentNanoseconds = nanoseconds
    }

    var now: MonotonicInstant {
        lock.withLock {
            MonotonicInstant(nanoseconds: currentNanoseconds)
        }
    }

    func advance(by duration: Duration) {
        let (seconds, attoseconds) = duration.components
        let nanosFromSecs = UInt64(max(0, seconds)) * 1_000_000_000
        let nanosFromAtto = UInt64(max(0, attoseconds) / 1_000_000_000)
        let totalNanos = nanosFromSecs + nanosFromAtto
        lock.withLock {
            currentNanoseconds &+= totalNanos
        }
    }

    func advance(nanoseconds: UInt64) {
        lock.withLock {
            currentNanoseconds &+= nanoseconds
        }
    }

    func advance(milliseconds: Double) {
        let nanos = UInt64(max(0, milliseconds * 1_000_000.0))
        advance(nanoseconds: nanos)
    }

    func duration(from start: MonotonicInstant, to end: MonotonicInstant) -> Duration {
        guard end.nanoseconds >= start.nanoseconds else {
            return .zero
        }
        let diff = end.nanoseconds - start.nanoseconds
        let clamped = min(diff, UInt64(Int64.max))
        return .nanoseconds(Int64(clamped))
    }
}
