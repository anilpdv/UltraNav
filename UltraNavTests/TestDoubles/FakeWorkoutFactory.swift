import Foundation
@testable import UltraNav

final class FakeWorkoutFactory: HealthKitWorkoutResourceCreating, @unchecked Sendable {
    let session = FakeWorkoutSession()
    let builder = FakeWorkoutBuilder()
    var shouldFailCreation: Bool = false

    @MainActor
    func createResources(
        configuration: WorkoutConfiguration,
        delegateBridge: HealthKitDelegateBridge
    ) throws -> HealthKitWorkoutResources {
        if shouldFailCreation {
            throw WorkoutServiceFailure.sessionCreationFailed
        }
        return HealthKitWorkoutResources(session: session, builder: builder)
    }
}
