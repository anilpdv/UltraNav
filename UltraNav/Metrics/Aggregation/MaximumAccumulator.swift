import Foundation

struct MaximumAccumulator: Equatable, Sendable {
    private(set) var maximum: Double?

    mutating func consume(_ value: Double) {
        guard value.isFinite else { return }
        maximum = max(maximum ?? value, value)
    }

    mutating func reset() {
        maximum = nil
    }
}
