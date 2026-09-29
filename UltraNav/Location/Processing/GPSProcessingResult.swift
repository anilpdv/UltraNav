import Foundation

/// Discriminated outcome of GPS sample evaluation.
public enum GPSProcessingResult: Equatable, Sendable {
    case accepted(GPSAcceptedSample)
    case rejected(GPSRejectedSample)
    case ignored(GPSIgnoredSample)
}
