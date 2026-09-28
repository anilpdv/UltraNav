import Foundation
import HealthKit

struct HealthKitWorkoutResources {
    let session: any HealthKitSessionManaging
    let builder: any HealthKitBuilderManaging
}

@MainActor
protocol HealthKitWorkoutResourceCreating: Sendable {
    func createResources(
        configuration: WorkoutConfiguration,
        delegateBridge: HealthKitDelegateBridge
    ) throws -> HealthKitWorkoutResources
}

final class HealthKitWorkoutFactory: HealthKitWorkoutResourceCreating, @unchecked Sendable {
    private let healthStore: HKHealthStore

    init(healthStore: HKHealthStore = HKHealthStore()) {
        self.healthStore = healthStore
    }

    @MainActor
    func createResources(
        configuration: WorkoutConfiguration,
        delegateBridge: HealthKitDelegateBridge
    ) throws -> HealthKitWorkoutResources {
        let hkConfig = configuration.makeHealthKitConfiguration()
        let session = try HKWorkoutSession(healthStore: healthStore, configuration: hkConfig)
        let builder = session.associatedWorkoutBuilder()

        builder.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: hkConfig
        )

        session.delegate = delegateBridge
        builder.delegate = delegateBridge

        let sessionAdapter = HealthKitSessionAdapter(session: session)
        let builderAdapter = HealthKitBuilderAdapter(builder: builder)

        return HealthKitWorkoutResources(session: sessionAdapter, builder: builderAdapter)
    }
}
