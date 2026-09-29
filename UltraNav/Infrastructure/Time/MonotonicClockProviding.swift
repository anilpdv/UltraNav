import Foundation

struct MonotonicInstant: Equatable, Comparable, Hashable, Sendable {
    let nanoseconds: UInt64

    static func < (lhs: MonotonicInstant, rhs: MonotonicInstant) -> Bool {
        lhs.nanoseconds < rhs.nanoseconds
    }
}

protocol MonotonicClockProviding: Sendable {
    var now: MonotonicInstant { get }
    func duration(from start: MonotonicInstant, to end: MonotonicInstant) -> Duration
}
