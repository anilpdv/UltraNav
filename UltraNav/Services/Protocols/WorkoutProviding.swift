import Foundation

/// Abstract interface for HealthKit and workout session lifecycle management.
@MainActor
protocol WorkoutProviding: AnyObject {
    var isSessionActive: Bool { get }
    var liveHeartRate: Double { get }
    var activeCalories: Double { get }
    var liveDistanceMeters: Double { get }

    func requestAuthorization() async -> Bool
    func startWorkout() async throws
    func pauseWorkout()
    func resumeWorkout()
    func stopWorkout() async throws
}
