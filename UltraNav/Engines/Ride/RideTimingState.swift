import Foundation

struct RideTimingState: Equatable, Sendable {
    private(set) var rideStartedAt: Date?
    private(set) var rideEndedAt: Date?
    private(set) var activeSegmentStartedAt: Date?
    private(set) var accumulatedMovingTime: TimeInterval = 0

    mutating func start(at date: Date) {
        rideStartedAt = date
        rideEndedAt = nil
        activeSegmentStartedAt = date
        accumulatedMovingTime = 0
    }

    mutating func pause(at date: Date) {
        closeActiveSegment(at: date)
    }

    mutating func resume(at date: Date) {
        guard activeSegmentStartedAt == nil else {
            return
        }
        activeSegmentStartedAt = date
    }

    mutating func finish(at date: Date) {
        closeActiveSegment(at: date)
        rideEndedAt = date
    }

    mutating func reset() {
        self = RideTimingState()
    }

    private mutating func closeActiveSegment(at date: Date) {
        guard let started = activeSegmentStartedAt else {
            return
        }
        let duration = max(0, date.timeIntervalSince(started))
        accumulatedMovingTime += duration
        activeSegmentStartedAt = nil
    }

    func elapsedTime(at now: Date) -> TimeInterval {
        guard let rideStartedAt else {
            return 0
        }
        let end = rideEndedAt ?? now
        return max(0, end.timeIntervalSince(rideStartedAt))
    }

    func movingTime(at now: Date) -> TimeInterval {
        guard let activeStart = activeSegmentStartedAt else {
            return accumulatedMovingTime
        }
        return accumulatedMovingTime + max(0, now.timeIntervalSince(activeStart))
    }
}
