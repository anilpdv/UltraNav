import Foundation

/// Operating mode of the GPS processor.
enum GPSProcessorMode: String, Equatable, Hashable, Codable, Sendable {
    case idle
    case recording
    case paused
    case recoveringFromPause
    case recoveringFromOutage
    case finished
}

/// Commands sent to control the GPS processing lifecycle.
enum GPSProcessorCommand: Equatable, Sendable {
    case start(at: Date)
    case pause(at: Date)
    case resume(at: Date)
    case locationUnavailable(at: Date)
    case locationAvailable(at: Date)
    case finish(at: Date)
    case reset
}

/// Internal mutable state maintained by the GPS processor.
struct GPSProcessingState: Equatable, Sendable {
    var mode: GPSProcessorMode = .idle
    var sequence: UInt64 = 0
    var lastAcceptedSample: LocationSample?
    var lastAcceptedSequence: UInt64?
    var lastReceivedTimestamp: Date?
    var totalDistanceMeters: Double = 0.0
    var movementState: MovementState = .unknown
    var consecutiveMovingEvidence: Int = 0
    var consecutiveStationaryEvidence: Int = 0
    var currentSpeedMetersPerSecond: Double?
    var currentSpeedMeasuredAt: Date?
    var acceptedSampleCount: Int = 0
    var rejectedSampleCount: Int = 0

    init(
        mode: GPSProcessorMode = .idle,
        sequence: UInt64 = 0,
        lastAcceptedSample: LocationSample? = nil,
        lastAcceptedSequence: UInt64? = nil,
        lastReceivedTimestamp: Date? = nil,
        totalDistanceMeters: Double = 0.0,
        movementState: MovementState = .unknown,
        consecutiveMovingEvidence: Int = 0,
        consecutiveStationaryEvidence: Int = 0,
        currentSpeedMetersPerSecond: Double? = nil,
        currentSpeedMeasuredAt: Date? = nil,
        acceptedSampleCount: Int = 0,
        rejectedSampleCount: Int = 0
    ) {
        self.mode = mode
        self.sequence = sequence
        self.lastAcceptedSample = lastAcceptedSample
        self.lastAcceptedSequence = lastAcceptedSequence
        self.lastReceivedTimestamp = lastReceivedTimestamp
        self.totalDistanceMeters = totalDistanceMeters
        self.movementState = movementState
        self.consecutiveMovingEvidence = consecutiveMovingEvidence
        self.consecutiveStationaryEvidence = consecutiveStationaryEvidence
        self.currentSpeedMetersPerSecond = currentSpeedMetersPerSecond
        self.currentSpeedMeasuredAt = currentSpeedMeasuredAt
        self.acceptedSampleCount = acceptedSampleCount
        self.rejectedSampleCount = rejectedSampleCount
    }
}

/// Immutable diagnostic snapshot of the GPS processor.
struct GPSProcessingSnapshot: Equatable, Sendable {
    let mode: GPSProcessorMode
    let totalDistanceMeters: Double
    let currentSpeedMetersPerSecond: Double?
    let speedFreshness: MetricFreshness?
    let movementState: MovementState
    let lastAcceptedSample: LocationSample?
    let acceptedSampleCount: Int
    let rejectedSampleCount: Int

    init(
        mode: GPSProcessorMode,
        totalDistanceMeters: Double,
        currentSpeedMetersPerSecond: Double?,
        speedFreshness: MetricFreshness?,
        movementState: MovementState,
        lastAcceptedSample: LocationSample?,
        acceptedSampleCount: Int,
        rejectedSampleCount: Int
    ) {
        self.mode = mode
        self.totalDistanceMeters = totalDistanceMeters
        self.currentSpeedMetersPerSecond = currentSpeedMetersPerSecond
        self.speedFreshness = speedFreshness
        self.movementState = movementState
        self.lastAcceptedSample = lastAcceptedSample
        self.acceptedSampleCount = acceptedSampleCount
        self.rejectedSampleCount = rejectedSampleCount
    }
}
