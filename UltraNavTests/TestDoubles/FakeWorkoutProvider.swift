import Foundation
@testable import UltraNav

actor FakeWorkoutProvider: WorkoutProviding {
    nonisolated let events: AsyncStream<WorkoutServiceEvent>
    private let continuation: AsyncStream<WorkoutServiceEvent>.Continuation

    enum Call: Equatable, Sendable {
        case authorizationStatus
        case requestAuthorization
        case prepare
        case start(Date)
        case pause
        case resume
        case finish(Date)
        case cancel
        case reset
    }

    private(set) var calls: [Call] = []

    var stubbedAuthorizationStatus: WorkoutAuthorizationStatus = .notDetermined

    var authorizationFailure: WorkoutServiceFailure?
    var preparationFailure: WorkoutServiceFailure?
    var startFailure: WorkoutServiceFailure?
    var pauseFailure: WorkoutServiceFailure?
    var resumeFailure: WorkoutServiceFailure?
    var finishFailure: WorkoutServiceFailure?

    var startGate: OperationGate?
    var finishGate: OperationGate?

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

    func setStartGate(_ gate: OperationGate?) {
        self.startGate = gate
    }

    func setFinishGate(_ gate: OperationGate?) {
        self.finishGate = gate
    }

    func authorizationStatus() async -> WorkoutAuthorizationStatus {
        calls.append(.authorizationStatus)
        return stubbedAuthorizationStatus
    }

    func requestAuthorization() async throws {
        calls.append(.requestAuthorization)
        authorizationCallCount += 1

        if let authorizationFailure {
            throw authorizationFailure
        }
    }

    func prepare() async throws {
        calls.append(.prepare)
        prepareCallCount += 1

        if let preparationFailure {
            throw preparationFailure
        }
    }

    func start(at date: Date) async throws {
        calls.append(.start(date))
        startDates.append(date)

        if let gate = startGate {
            try await gate.wait()
        }

        if let startFailure {
            throw startFailure
        }
    }

    func pause() async throws {
        calls.append(.pause)
        pauseCallCount += 1

        if let pauseFailure {
            throw pauseFailure
        }
    }

    func resume() async throws {
        calls.append(.resume)
        resumeCallCount += 1

        if let resumeFailure {
            throw resumeFailure
        }
    }

    func finish(at date: Date) async throws {
        calls.append(.finish(date))
        finishDates.append(date)

        if let gate = finishGate {
            try await gate.wait()
        }

        if let finishFailure {
            throw finishFailure
        }
    }

    func cancel() async {
        calls.append(.cancel)
        cancelCallCount += 1
    }

    func reset() async {
        calls.append(.reset)
        resetCallCount += 1
    }

    nonisolated func send(_ event: WorkoutServiceEvent) {
        continuation.yield(event)
    }

    nonisolated func finishEvents() {
        continuation.finish()
    }

    func clear() {
        calls.removeAll()
        authorizationCallCount = 0
        prepareCallCount = 0
        startDates.removeAll()
        pauseCallCount = 0
        resumeCallCount = 0
        finishDates.removeAll()
        cancelCallCount = 0
        resetCallCount = 0
        startGate = nil
        finishGate = nil
    }
}
