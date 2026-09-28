import Foundation

struct SystemClock: ClockProviding, Sendable {
    var now: Date {
        Date()
    }
}
