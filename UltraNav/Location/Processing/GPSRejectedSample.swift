import Foundation

/// Rejected location sample with diagnostic reason and sequence number.
public struct GPSRejectedSample: Equatable, Sendable {
    public let sample: LocationSample
    public let reason: GPSSampleRejectionReason
    public let sequence: UInt64

    public init(sample: LocationSample, reason: GPSSampleRejectionReason, sequence: UInt64) {
        self.sample = sample
        self.reason = reason
        self.sequence = sequence
    }
}

/// Reason why a sample was ignored (e.g. outside active recording lifecycle).
public enum GPSIgnoredReason: Equatable, Sendable {
    case notRecording
    case finished
}

/// Sample received when processor is not actively recording ride metrics.
public struct GPSIgnoredSample: Equatable, Sendable {
    public let sample: LocationSample
    public let reason: GPSIgnoredReason
    public let sequence: UInt64

    public init(sample: LocationSample, reason: GPSIgnoredReason, sequence: UInt64) {
        self.sample = sample
        self.reason = reason
        self.sequence = sequence
    }
}
