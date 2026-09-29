import Foundation

/// Estimated speed and its derivation source.
public struct GPSSpeedEstimate: Equatable, Sendable {
    public enum Source: String, Equatable, Hashable, Codable, Sendable {
        case platformReported
        case positionDerived
        case unavailable
    }

    public let metersPerSecond: Double?
    public let source: Source

    public init(metersPerSecond: Double?, source: Source) {
        self.metersPerSecond = metersPerSecond
        self.source = source
    }
}

/// Protocol isolating speed selection between system-reported and position-derived speed.
public protocol GPSSpeedEstimating: Sendable {
    func estimate(
        current: LocationSample,
        previous: LocationSample?,
        distanceMeters: Double?,
        timeDeltaSeconds: TimeInterval?,
        configuration: GPSProcessingConfiguration
    ) -> GPSSpeedEstimate
}

/// Standard speed estimator choosing platform reported speed with fallback to position implied speed.
public struct GPSSpeedEstimator: GPSSpeedEstimating, Sendable {
    public init() {}

    public func estimate(
        current: LocationSample,
        previous: LocationSample?,
        distanceMeters: Double?,
        timeDeltaSeconds: TimeInterval?,
        configuration: GPSProcessingConfiguration
    ) -> GPSSpeedEstimate {
        // 1. Check reported speed from platform
        if let reported = current.speedMetersPerSecond,
           reported.isFinite,
           !reported.isNaN,
           reported >= 0.0,
           reported <= configuration.maximumPlausibleSpeedMetersPerSecond {
            return GPSSpeedEstimate(metersPerSecond: reported, source: .platformReported)
        }

        // 2. Fallback to position-derived implied speed
        if let dist = distanceMeters,
           let dt = timeDeltaSeconds,
           dt > 0.0,
           dist.isFinite,
           !dist.isNaN,
           dist >= 0.0 {
            let derived = dist / dt
            if derived.isFinite, !derived.isNaN, derived <= configuration.maximumPlausibleSpeedMetersPerSecond {
                return GPSSpeedEstimate(metersPerSecond: derived, source: .positionDerived)
            }
        }

        return GPSSpeedEstimate(metersPerSecond: nil, source: .unavailable)
    }
}
