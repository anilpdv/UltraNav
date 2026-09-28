import Foundation
import HealthKit

@MainActor
protocol HealthKitSessionManaging: AnyObject {
    func prepare()
    func startActivity(at date: Date)
    func pause()
    func resume()
    func stopActivity(at date: Date)
    func end()
}

@MainActor
protocol HealthKitBuilderManaging: AnyObject {
    func beginCollection(at date: Date) async throws
    func endCollection(at date: Date) async throws
    func finishWorkout() async throws -> CompletedWorkoutReference
    func statistics(for type: HKQuantityType) -> HKStatistics?
}

@MainActor
final class HealthKitSessionAdapter: HealthKitSessionManaging {
    let session: HKWorkoutSession

    init(session: HKWorkoutSession) {
        self.session = session
    }

    func prepare() {
        session.prepare()
    }

    func startActivity(at date: Date) {
        session.startActivity(with: date)
    }

    func pause() {
        session.pause()
    }

    func resume() {
        session.resume()
    }

    func stopActivity(at date: Date) {
        session.stopActivity(with: date)
    }

    func end() {
        session.end()
    }
}

@MainActor
final class HealthKitBuilderAdapter: HealthKitBuilderManaging {
    let builder: HKLiveWorkoutBuilder

    init(builder: HKLiveWorkoutBuilder) {
        self.builder = builder
    }

    func beginCollection(at date: Date) async throws {
        try await builder.beginCollection(at: date)
    }

    func endCollection(at date: Date) async throws {
        try await builder.endCollection(at: date)
    }

    func finishWorkout() async throws -> CompletedWorkoutReference {
        guard let workout = try await builder.finishWorkout() else {
            throw WorkoutServiceFailure.workoutSaveFailed
        }
        return CompletedWorkoutReference(
            identifier: workout.uuid,
            startDate: workout.startDate,
            endDate: workout.endDate
        )
    }

    func statistics(for type: HKQuantityType) -> HKStatistics? {
        builder.statistics(for: type)
    }
}
