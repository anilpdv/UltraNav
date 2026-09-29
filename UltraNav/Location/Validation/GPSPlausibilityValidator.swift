import Foundation

/// Outcome of geographic movement plausibility checks between consecutive samples.
public enum GPSPlausibilityValidation: Equatable, Sendable {
    case plausible(distanceMeters: Double, impliedSpeedMetersPerSecond: Double, accuracyOverlap: Bool)
    case invalidTimeDelta
    case nonFiniteCalculation
    case implausibleDistanceJump(distanceMeters: Double)
    case implausibleSpeed(metersPerSecond: Double)
}

/// Validator evaluating distance and implied velocity bounds between GPS samples.
public struct GPSPlausibilityValidator: Sendable {
    private let distanceCalculator: any CoordinateDistanceCalculating

    public init(distanceCalculator: any CoordinateDistanceCalculating = CoreLocationDistanceCalculator()) {
        self.distanceCalculator = distanceCalculator
    }

    public func validate(
        current: LocationSample,
        previous: LocationSample,
        configuration: GPSProcessingConfiguration
    ) -> GPSPlausibilityValidation {
        let timeDelta = current.timestamp.timeIntervalSince(previous.timestamp)
        guard timeDelta > 0.0 else {
            return .invalidTimeDelta
        }

        let distance = distanceCalculator.distance(from: previous.coordinate, to: current.coordinate)
        guard distance.isFinite, !distance.isNaN, distance >= 0.0 else {
            return .nonFiniteCalculation
        }

        let impliedSpeed = distance / timeDelta
        guard impliedSpeed.isFinite, !impliedSpeed.isNaN else {
            return .nonFiniteCalculation
        }

        if impliedSpeed > configuration.maximumPlausibleSpeedMetersPerSecond {
            return .implausibleSpeed(metersPerSecond: impliedSpeed)
        }

        // Evaluate accuracy overlap drift: distance <= (acc1 + acc2) * multiplier
        let accuracyThreshold = (previous.horizontalAccuracyMeters + current.horizontalAccuracyMeters) * configuration.accuracyOverlapMultiplier
        let accuracyOverlap = distance <= accuracyThreshold

        return .plausible(
            distanceMeters: distance,
            impliedSpeedMetersPerSecond: impliedSpeed,
            accuracyOverlap: accuracyOverlap
        )
    }
}
