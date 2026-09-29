import Foundation

/// Specific reason why a location sample was rejected by the GPS processing pipeline.
public enum GPSSampleRejectionReason: Equatable, Sendable {
    case invalidCoordinate
    case invalidHorizontalAccuracy
    case accuracyTooPoor(actualMeters: Double, maximumMeters: Double)
    case timestampTooOld(ageSeconds: TimeInterval)
    case outOfOrderTimestamp
    case duplicateTimestamp
    case implausibleDistanceJump(distanceMeters: Double)
    case implausibleSpeed(metersPerSecond: Double)
    case accuracyOverlapIndicatesDrift
    case processorPaused
    case awaitingResumeAnchor
    case awaitingOutageRecoveryAnchor
    case insufficientTimeDelta
    case nonFiniteCalculation
}
