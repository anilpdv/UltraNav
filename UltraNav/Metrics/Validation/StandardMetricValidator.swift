import Foundation

struct StandardMetricValidator: MetricValidating, Sendable {
    func validate(
        _ observation: MetricObservation,
        policy: MetricValidationPolicy = .standard
    ) -> MetricValidationResult {
        guard observation.value.kind == observation.kind else {
            return .rejected(.typeMismatch)
        }

        let val = observation.value.doubleValue
        guard val.isFinite else {
            return .rejected(.nonFiniteValue)
        }

        switch observation.value {
        case .speedMetersPerSecond(let speed):
            if speed < 0 { return .rejected(.belowMinimum) }
            if speed > policy.maximumSpeedMetersPerSecond { return .rejected(.aboveMaximum) }

        case .cumulativeDistanceMeters(let dist):
            if dist < 0 { return .rejected(.belowMinimum) }

        case .heartRateBeatsPerMinute(let hr):
            if hr <= 0 { return .rejected(.belowMinimum) }
            if hr > policy.maximumHeartRateBPM { return .rejected(.aboveMaximum) }

        case .cadenceRevolutionsPerMinute(let cad):
            if cad < 0 { return .rejected(.belowMinimum) }
            if cad > policy.maximumCadenceRPM { return .rejected(.aboveMaximum) }

        case .powerWatts(let pwr):
            if pwr < policy.minimumPowerWatts { return .rejected(.belowMinimum) }
            if pwr > policy.maximumPowerWatts { return .rejected(.aboveMaximum) }

        case .cumulativeActiveEnergyKilocalories(let kcal):
            if kcal < 0 { return .rejected(.belowMinimum) }

        case .altitudeMeters(let alt):
            if alt < policy.minimumAltitudeMeters { return .rejected(.belowMinimum) }
            if alt > policy.maximumAltitudeMeters { return .rejected(.aboveMaximum) }
        }

        return .accepted(observation)
    }
}
