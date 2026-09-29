import Foundation

/// Protocol for time-bounded sliding-window speed smoothing.
public protocol GPSSpeedSmoothing: Sendable {
    mutating func add(speedMetersPerSecond: Double, at timestamp: Date)
    func value(at timestamp: Date) -> Double?
    mutating func reset()
}

/// Time-bounded sliding window speed smoother.
public struct TimeWeightedSpeedSmoother: GPSSpeedSmoothing, Sendable {
    private struct Entry: Equatable, Sendable {
        let speed: Double
        let timestamp: Date
    }

    private let windowSeconds: TimeInterval
    private var entries: [Entry] = []

    public init(windowSeconds: TimeInterval = 5.0) {
        self.windowSeconds = windowSeconds
    }

    public mutating func add(speedMetersPerSecond: Double, at timestamp: Date) {
        guard speedMetersPerSecond.isFinite, !speedMetersPerSecond.isNaN, speedMetersPerSecond >= 0.0 else {
            return
        }

        entries.append(Entry(speed: speedMetersPerSecond, timestamp: timestamp))
        trimOldEntries(relativeTo: timestamp)
    }

    public func value(at timestamp: Date) -> Double? {
        let active = entries.filter { timestamp.timeIntervalSince($0.timestamp) <= windowSeconds && timestamp.timeIntervalSince($0.timestamp) >= 0 }
        guard !active.isEmpty else {
            return nil
        }

        if active.count == 1 {
            return active[0].speed
        }

        // Compute average over the active window
        let total = active.reduce(0.0) { $0 + $1.speed }
        return total / Double(active.count)
    }

    public mutating func reset() {
        entries.removeAll(keepingCapacity: false)
    }

    private mutating func trimOldEntries(relativeTo currentTimestamp: Date) {
        entries.removeAll { currentTimestamp.timeIntervalSince($0.timestamp) > windowSeconds }
    }
}
