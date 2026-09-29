import Foundation

/// Outcome of validating horizontal accuracy.
public enum GPSAccuracyValidation: Equatable, Sendable {
    case accepted(GPSQuality)
    case invalid
    case tooPoor(actualMeters: Double, maximumMeters: Double)
}

/// Protocol isolating horizontal accuracy validation.
public protocol GPSAccuracyValidating: Sendable {
    func validate(
        _ sample: LocationSample,
        configuration: GPSProcessingConfiguration
    ) -> GPSAccuracyValidation
}

/// Standard accuracy validator enforcing finite bounds and maximum accuracy ceilings.
public struct GPSAccuracyValidator: GPSAccuracyValidating, Sendable {
    public init() {}

    public func validate(
        _ sample: LocationSample,
        configuration: GPSProcessingConfiguration
    ) -> GPSAccuracyValidation {
        let acc = sample.horizontalAccuracyMeters

        guard acc.isFinite, !acc.isNaN, acc >= 0.0 else {
            return .invalid
        }

        if acc > configuration.maximumHorizontalAccuracyMeters {
            return .tooPoor(actualMeters: acc, maximumMeters: configuration.maximumHorizontalAccuracyMeters)
        }

        let quality = GPSQuality.classify(horizontalAccuracyMeters: acc)
        return .accepted(quality)
    }
}
