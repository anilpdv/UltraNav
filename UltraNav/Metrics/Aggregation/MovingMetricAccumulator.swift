import Foundation

struct MetricAggregationPolicy: Equatable, Sendable {
    enum ZeroBehavior: Equatable, Sendable {
        case include
        case exclude
        case includeOnlyWhileMoving
    }

    let speedZero: ZeroBehavior
    let cadenceZero: ZeroBehavior
    let powerZero: ZeroBehavior

    static let standard = MetricAggregationPolicy(
        speedZero: .includeOnlyWhileMoving,
        cadenceZero: .include,
        powerZero: .include
    )
}

struct MovingMetricAccumulator: Equatable, Sendable {
    private(set) var elapsedTimeSeconds: TimeInterval = 0
    private(set) var activeTimeSeconds: TimeInterval = 0
    private(set) var movingTimeSeconds: TimeInterval = 0

    private var rideStartedAt: Date?
    private var lastActiveTickAt: Date?
    private var movementThresholdMetersPerSecond: Double

    init(movementThresholdMetersPerSecond: Double = 0.5) {
        self.movementThresholdMetersPerSecond = movementThresholdMetersPerSecond
    }

    mutating func start(at date: Date) {
        rideStartedAt = date
        lastActiveTickAt = date
    }

    mutating func tick(at date: Date, isPaused: Bool, currentSpeedMetersPerSecond: Double?) {
        guard let start = rideStartedAt else { return }
        elapsedTimeSeconds = max(0, date.timeIntervalSince(start))

        guard !isPaused, let lastTick = lastActiveTickAt else {
            lastActiveTickAt = isPaused ? nil : date
            return
        }

        let dt = date.timeIntervalSince(lastTick)
        if dt > 0 && dt <= 5.0 {
            activeTimeSeconds += dt
            if let speed = currentSpeedMetersPerSecond, speed >= movementThresholdMetersPerSecond {
                movingTimeSeconds += dt
            }
        }
        lastActiveTickAt = date
    }

    mutating func resume(at date: Date) {
        lastActiveTickAt = date
    }

    mutating func pause(at date: Date) {
        if let lastTick = lastActiveTickAt {
            let dt = date.timeIntervalSince(lastTick)
            if dt > 0 && dt <= 5.0 {
                activeTimeSeconds += dt
            }
        }
        lastActiveTickAt = nil
    }

    mutating func finish(at date: Date) {
        guard let start = rideStartedAt else { return }
        elapsedTimeSeconds = max(0, date.timeIntervalSince(start))
        if let lastTick = lastActiveTickAt {
            let dt = date.timeIntervalSince(lastTick)
            if dt > 0 && dt <= 5.0 {
                activeTimeSeconds += dt
            }
        }
        lastActiveTickAt = nil
    }

    mutating func reset() {
        elapsedTimeSeconds = 0
        activeTimeSeconds = 0
        movingTimeSeconds = 0
        rideStartedAt = nil
        lastActiveTickAt = nil
    }
}
