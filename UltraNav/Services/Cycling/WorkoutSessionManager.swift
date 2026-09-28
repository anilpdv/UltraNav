import Foundation
import HealthKit
import OSLog

@MainActor
@Observable
public final class WorkoutSessionManager: NSObject, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    public static let shared = WorkoutSessionManager()

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    public var isSessionActive: Bool = false
    public var liveHeartRate: Double = 0
    public var activeCalories: Double = 0
    public var liveDistanceMeters: Double = 0

    public override init() {
        super.init()
    }

    public func requestAuthorization() async -> Bool {
        await requestHealthKitAuthorization()
    }

    public func requestHealthKitAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }

        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingCadence)!,
            HKQuantityType.quantityType(forIdentifier: .cyclingPower)!
        ]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            return true
        } catch {
            AppLogger.lifecycle.error("HealthKit authorization failed: \(String(describing: type(of: error)), privacy: .public)")
            return false
        }
    }

    public func startWorkout() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .cycling
        configuration.locationType = .outdoor

        do {
            let newSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            let newBuilder = newSession.associatedWorkoutBuilder()

            newSession.delegate = self
            newBuilder.delegate = self
            newBuilder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)

            self.session = newSession
            self.builder = newBuilder

            let startDate = Date()
            newSession.startActivity(with: startDate)
            try await newBuilder.beginCollection(at: startDate)

            self.isSessionActive = true
            AppLogger.lifecycle.info("Started HealthKit outdoor cycling workout session")
        } catch {
            AppLogger.lifecycle.error("Failed to start HealthKit workout: \(String(describing: type(of: error)), privacy: .public)")
        }
    }

    public func pauseWorkout() {
        session?.pause()
    }

    public func resumeWorkout() {
        session?.resume()
    }

    public func stopWorkout() async {
        guard let session, let builder else { return }

        let endDate = Date()
        session.end()

        do {
            try await builder.endCollection(at: endDate)
            let _ = try await builder.finishWorkout()
            AppLogger.lifecycle.info("Finished and saved HealthKit cycling workout")
        } catch {
            AppLogger.lifecycle.error("Failed to finish HealthKit workout: \(String(describing: type(of: error)), privacy: .public)")
        }

        self.isSessionActive = false
        self.session = nil
        self.builder = nil
    }

    // MARK: - HKWorkoutSessionDelegate

    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        Task { @MainActor in
            self.isSessionActive = (toState == .running)
        }
    }

    nonisolated public func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        AppLogger.lifecycle.error("Workout session failed: \(String(describing: type(of: error)), privacy: .public)")
    }

    // MARK: - HKLiveWorkoutBuilderDelegate

    nonisolated public func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }

    nonisolated public func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { continue }
            let statistics = workoutBuilder.statistics(for: quantityType)

            Task { @MainActor in
                if quantityType == HKQuantityType.quantityType(forIdentifier: .heartRate) {
                    let unit = HKUnit.count().unitDivided(by: .minute())
                    if let value = statistics?.mostRecentQuantity()?.doubleValue(for: unit) {
                        self.liveHeartRate = value
                    }
                } else if quantityType == HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
                    let unit = HKUnit.kilocalorie()
                    if let value = statistics?.sumQuantity()?.doubleValue(for: unit) {
                        self.activeCalories = value
                    }
                } else if quantityType == HKQuantityType.quantityType(forIdentifier: .distanceCycling) {
                    let unit = HKUnit.meter()
                    if let value = statistics?.sumQuantity()?.doubleValue(for: unit) {
                        self.liveDistanceMeters = value
                    }
                }
            }
        }
    }
}
