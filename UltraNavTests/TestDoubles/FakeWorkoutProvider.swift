import Foundation
@testable import UltraNav

actor FakeWorkoutProvider: WorkoutProviding {
    nonisolated let events: AsyncStream<WorkoutServiceEvent>

    private let continuation: AsyncStream<WorkoutServiceEvent>.Continuation

    var stubbedAuthorizationStatus: WorkoutAuthorizationStatus = .notDetermined

    var authorizationFailure: WorkoutServiceFailure?
    var preparationFailure: WorkoutServiceFailure?
    var startFailure: WorkoutServiceFailure?
    var pauseFailure: WorkoutServiceFailure?
    var resumeFailure: WorkoutServiceFailure?
    var finishFailure: WorkoutServiceFailure?

    private(set) var authorizationCallCount = 0
    private(set) var prepareCallCount = 0
    private(set) var startDates: [Date] = []
    private(set) var pauseCallCount = 0
    private(set) var resumeCallCount = 0
    private(set) var finishDates: [Date] = []
    private(set) var cancelCallCount = 0
    private(set) var resetCallCount = 0

    init() {
        let pair = AsyncStream.makeStream(of: WorkoutServiceEvent.self)
        self.events = pair.stream
        self.continuation = pair.continuation
    }

    func setStubbedAuthorizationStatus(_ status: WorkoutAuthorizationStatus) {
        self.stubbedAuthorizationStatus = status
    }

    func setAuthorizationFailure(_ failure: WorkoutServiceFailure?) {
        self.authorizationFailure = failure
    }

    func setPreparationFailure(_ failure: WorkoutServiceFailure?) {
        self.preparationFailure = failure
    }

    func setStartFailure(_ failure: WorkoutServiceFailure?) {
        self.startFailure = failure
    }

    func setPauseFailure(_ failure: WorkoutServiceFailure?) {
        self.pauseFailure = failure
    }

    func setResumeFailure(_ failure: WorkoutServiceFailure?) {
        self.resumeFailure = failure
    }

    func setFinishFailure(_ failure: WorkoutServiceFailure?) {
        self.finishFailure = failure
    }

    func authorizationStatus() async -> WorkoutAuthorizationStatus {
        stubbedAuthorizationStatus
    }

    func requestAuthorization() async throws {
        authorizationCallCount += 1

        if let authorizationFailure {
            throw authorizationFailure
        }
    }

    func prepare() async throws {
        prepareCallCount += 1

        if let preparationFailure {
            throw preparationFailure
        }
    }

    func start(at date: Date) async throws {
        startDates.append(date)

        if let startFailure {
            throw startFailure
        }
    }

    func pause() async throws {
        pauseCallCount += 1

        if let pauseFailure {
            throw pauseFailure
        }
    }

    func resume() async throws {
        resumeCallCount += 1

        if let resumeFailure {
            throw resumeFailure
        }
    }

    func finish(at date: Date) async throws {
        finishDates.append(date)

        if let finishFailure {
            throw finishFailure
        }
    }

    func cancel() async {
        cancelCallCount += 1
    }

    func reset() async {
        resetCallCount += 1
    }

    nonisolated func send(_ event: WorkoutServiceEvent) {
        continuation.yield(event)
    }

    nonisolated func finishEvents() {
        continuation.finish()
    }
}
