import Foundation
import HealthKit

enum HealthKitDataTypes {
    static var workoutType: HKWorkoutType {
        HKObjectType.workoutType()
    }

    static var heartRate: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .heartRate)
    }

    static var activeEnergy: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)
    }

    static var cyclingDistance: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .distanceCycling)
    }

    static var typesToShare: Set<HKSampleType> {
        [workoutType]
    }

    static var typesToRead: Set<HKObjectType> {
        var result: Set<HKObjectType> = []
        if let heartRate {
            result.insert(heartRate)
        }
        if let activeEnergy {
            result.insert(activeEnergy)
        }
        if let cyclingDistance {
            result.insert(cyclingDistance)
        }
        return result
    }
}
