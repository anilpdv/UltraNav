import Foundation
import HealthKit

@MainActor
protocol HealthKitDelegateBridgeDelegate: AnyObject {
    func workoutSessionChanged(
        to newState: HKWorkoutSessionState,
        from oldState: HKWorkoutSessionState,
        at date: Date
    )
    func workoutSessionFailed(_ error: Error)
    func workoutBuilderCollected(statisticsFor types: Set<HKSampleType>)
    func workoutBuilderCollectedEvent()
}

final class HealthKitDelegateBridge: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate, @unchecked Sendable {
    weak var delegate: (any HealthKitDelegateBridgeDelegate)?

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.workoutSessionChanged(to: toState, from: fromState, at: date)
        }
    }

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.workoutSessionFailed(error)
        }
    }

    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.workoutBuilderCollected(statisticsFor: collectedTypes)
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(
        _ workoutBuilder: HKLiveWorkoutBuilder
    ) {
        Task { @MainActor [weak self] in
            self?.delegate?.workoutBuilderCollectedEvent()
        }
    }
}
