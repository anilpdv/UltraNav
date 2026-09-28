import Foundation
import HealthKit
@testable import UltraNav

@MainActor
final class FakeWorkoutBuilder: HealthKitBuilderManaging {
    private(set) var beginDates: [Date] = []
    private(set) var endDates: [Date] = []
    private(set) var finishCallCount = 0

    var beginFailure: WorkoutServiceFailure?
    var endFailure: WorkoutServiceFailure?
    var finishFailure: WorkoutServiceFailure?

    var completedWorkout = CompletedWorkoutReference(
        identifier: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        startDate: Date(timeIntervalSince1970: 1_700_000_000),
        endDate: Date(timeIntervalSince1970: 1_700_003_600)
    )

    func beginCollection(at date: Date) async throws {
        beginDates.append(date)
        if let beginFailure {
            throw beginFailure
        }
    }

    func endCollection(at date: Date) async throws {
        endDates.append(date)
        if let endFailure {
            throw endFailure
        }
    }

    func finishWorkout() async throws -> CompletedWorkoutReference {
        finishCallCount += 1
        if let finishFailure {
            throw finishFailure
        }
        return completedWorkout
    }

    func statistics(for type: HKQuantityType) -> HKStatistics? {
        nil
    }
}
