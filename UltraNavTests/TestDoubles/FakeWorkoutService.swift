import Foundation
@testable import UltraNav

/// Controllable fake workout service for unit tests.
@MainActor
public final class FakeWorkoutService: WorkoutProviding {
    public var isSessionActive: Bool = false
    public var liveHeartRate: Double = 0
    public var activeCalories: Double = 0
    public var liveDistanceMeters: Double = 0

    public var authorizationGranted: Bool = true
    public var startShouldThrow: Error?
    public var finishShouldThrow: Error?

    public var startCalled: Bool = false
    public var pauseCalled: Bool = false
    public var resumeCalled: Bool = false
    public var stopCalled: Bool = false

    public init() {}

    public func requestAuthorization() async -> Bool {
        authorizationGranted
    }

    public func startWorkout() async throws {
        if let startShouldThrow {
            throw startShouldThrow
        }
        startCalled = true
        isSessionActive = true
    }

    public func pauseWorkout() {
        pauseCalled = true
        isSessionActive = false
    }

    public func resumeWorkout() {
        resumeCalled = true
        isSessionActive = true
    }

    public func stopWorkout() async throws {
        if let finishShouldThrow {
            throw finishShouldThrow
        }
        stopCalled = true
        isSessionActive = false
    }
}
