import Foundation

/// Outcome of validating sample timestamp order and age.
public enum GPSTimestampValidation: Equatable, Sendable {
    case valid
    case tooOld(ageSeconds: TimeInterval)
    case outOfOrder
    case duplicate
    case insufficientDelta
}

/// Protocol isolating timestamp validation rules.
public protocol GPSTimestampValidating: Sendable {
    func validate(
        sampleTimestamp: Date,
        receivedAt: Date,
        previousAcceptedTimestamp: Date?,
        configuration: GPSProcessingConfiguration
    ) -> GPSTimestampValidation
}

/// Standard timestamp validator enforcing age bounds and strict monotonicity.
public struct GPSTimestampValidator: GPSTimestampValidating, Sendable {
    public init() {}

    public func validate(
        sampleTimestamp: Date,
        receivedAt: Date,
        previousAcceptedTimestamp: Date?,
        configuration: GPSProcessingConfiguration
    ) -> GPSTimestampValidation {
        // 1. Age Validation
        let age = receivedAt.timeIntervalSince(sampleTimestamp)
        let effectiveAge = max(0.0, age)
        if effectiveAge > configuration.maximumSampleAgeSeconds {
            return .tooOld(ageSeconds: effectiveAge)
        }

        // 2. Monotonicity and Duplicate Checking against previous accepted sample
        if let prevTime = previousAcceptedTimestamp {
            let delta = sampleTimestamp.timeIntervalSince(prevTime)
            if delta < 0.0 {
                return .outOfOrder
            }
            if delta == 0.0 {
                return .duplicate
            }
            if delta < configuration.minimumTimeDeltaSeconds {
                return .insufficientDelta
            }
        }

        return .valid
    }
}
