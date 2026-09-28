import Foundation
@testable import UltraNav

@MainActor
final class FakeWorkoutSession: HealthKitSessionManaging {
    private(set) var prepareCallCount = 0
    private(set) var startDates: [Date] = []
    private(set) var pauseCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var stopDates: [Date] = []
    private(set) var endCallCount = 0

    func prepare() {
        prepareCallCount += 1
    }

    func startActivity(at date: Date) {
        startDates.append(date)
    }

    func pause() {
        pauseCallCount += 1
    }

    func resume() {
        resumeCallCount += 1
    }

    func stopActivity(at date: Date) {
        stopDates.append(date)
    }

    func end() {
        endCallCount += 1
    }
}
