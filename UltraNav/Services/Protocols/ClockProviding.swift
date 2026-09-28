import Foundation

/// Protocol abstracting system time for deterministic testing.
protocol ClockProviding: Sendable {
    var now: Date { get }
}

/// Standard production system clock implementation.
struct SystemClock: ClockProviding {
    init() {}

    var now: Date {
        Date()
    }
}
