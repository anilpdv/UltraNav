import Foundation
import HealthKit

struct HealthKitMetricConverter: Sendable {
    func metric(
        for type: HKQuantityType,
        statistics: HKStatistics,
        timestamp: Date
    ) -> WorkoutMetric? {
        switch type.identifier {
        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return heartRateMetric(statistics: statistics, timestamp: timestamp)
        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
            return activeEnergyMetric(statistics: statistics, timestamp: timestamp)
        case HKQuantityTypeIdentifier.distanceCycling.rawValue:
            return cyclingDistanceMetric(statistics: statistics, timestamp: timestamp)
        default:
            return nil
        }
    }

    private func heartRateMetric(statistics: HKStatistics, timestamp: Date) -> WorkoutMetric? {
        let unit = HKUnit.count().unitDivided(by: .minute())
        guard let quantity = statistics.mostRecentQuantity() else { return nil }
        let value = quantity.doubleValue(for: unit)
        guard value.isFinite, value >= 0 else { return nil }
        return .heartRate(beatsPerMinute: value, timestamp: timestamp)
    }

    private func activeEnergyMetric(statistics: HKStatistics, timestamp: Date) -> WorkoutMetric? {
        guard let quantity = statistics.sumQuantity() else { return nil }
        let value = quantity.doubleValue(for: .kilocalorie())
        guard value.isFinite, value >= 0 else { return nil }
        return .activeEnergy(kilocalories: value, timestamp: timestamp)
    }

    private func cyclingDistanceMetric(statistics: HKStatistics, timestamp: Date) -> WorkoutMetric? {
        guard let quantity = statistics.sumQuantity() else { return nil }
        let value = quantity.doubleValue(for: .meter())
        guard value.isFinite, value >= 0 else { return nil }
        return .cyclingDistance(meters: value, timestamp: timestamp)
    }
}
