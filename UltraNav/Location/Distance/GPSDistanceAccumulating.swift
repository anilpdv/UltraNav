import Foundation

/// Result of evaluating distance accumulation for an accepted GPS sample.
public struct GPSDistanceAccumulationResult: Equatable, Sendable {
    public let incrementMeters: Double
    public let totalMeters: Double
    public let shouldAdvanceAnchor: Bool

    public init(
        incrementMeters: Double,
        totalMeters: Double,
        shouldAdvanceAnchor: Bool
    ) {
        self.incrementMeters = incrementMeters
        self.totalMeters = totalMeters
        self.shouldAdvanceAnchor = shouldAdvanceAnchor
    }
}

/// Protocol isolating GPS ride distance accumulation logic.
public protocol GPSDistanceAccumulating: Sendable {
    var totalDistanceMeters: Double { get }
    mutating func evaluate(
        previous: LocationSample?,
        current: LocationSample,
        movementState: MovementState,
        distanceMeters: Double?,
        bridgeAllowed: Bool
    ) -> GPSDistanceAccumulationResult
    mutating func reset()
}

/// Standard distance accumulator enforcing movement state gating and anchor advancement.
public struct GPSDistanceAccumulator: GPSDistanceAccumulating, Sendable {
    public private(set) var totalDistanceMeters: Double = 0.0

    public init(initialDistanceMeters: Double = 0.0) {
        self.totalDistanceMeters = initialDistanceMeters
    }

    public mutating func evaluate(
        previous: LocationSample?,
        current: LocationSample,
        movementState: MovementState,
        distanceMeters: Double?,
        bridgeAllowed: Bool
    ) -> GPSDistanceAccumulationResult {
        guard previous != nil, bridgeAllowed, let dist = distanceMeters, dist.isFinite, !dist.isNaN, dist > 0.0 else {
            return GPSDistanceAccumulationResult(
                incrementMeters: 0.0,
                totalMeters: totalDistanceMeters,
                shouldAdvanceAnchor: true
            )
        }

        let increment: Double
        if movementState == .moving {
            increment = dist
            totalDistanceMeters += dist
        } else {
            increment = 0.0
        }

        return GPSDistanceAccumulationResult(
            incrementMeters: increment,
            totalMeters: totalDistanceMeters,
            shouldAdvanceAnchor: true
        )
    }

    public mutating func reset() {
        totalDistanceMeters = 0.0
    }
}
