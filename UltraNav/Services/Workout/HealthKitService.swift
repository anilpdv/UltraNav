import Foundation
import HealthKit
import OSLog

@MainActor
final class HealthKitService: NSObject, WorkoutProviding, HealthKitDelegateBridgeDelegate {
    nonisolated let events: AsyncStream<WorkoutServiceEvent>
    private let continuation: AsyncStream<WorkoutServiceEvent>.Continuation

    private let authorizationClient: any HealthKitAuthorizing
    private let resourceFactory: any HealthKitWorkoutResourceCreating
    private let clock: any ClockProviding
    private let configuration: WorkoutConfiguration
    private let metricConverter: HealthKitMetricConverter
    private let delegateBridge: HealthKitDelegateBridge

    private(set) var state: WorkoutServiceState = .idle
    private var session: (any HealthKitSessionManaging)?
    private var builder: (any HealthKitBuilderManaging)?

    init(
        authorizationClient: any HealthKitAuthorizing = HealthKitAuthorizationClient(),
        resourceFactory: any HealthKitWorkoutResourceCreating = HealthKitWorkoutFactory(),
        clock: any ClockProviding = SystemClock(),
        configuration: WorkoutConfiguration = .outdoorCycling,
        metricConverter: HealthKitMetricConverter = HealthKitMetricConverter(),
        delegateBridge: HealthKitDelegateBridge = HealthKitDelegateBridge()
    ) {
        let pair = AsyncStream.makeStream(
            of: WorkoutServiceEvent.self,
            bufferingPolicy: .bufferingNewest(50)
        )
        self.events = pair.stream
        self.continuation = pair.continuation

        self.authorizationClient = authorizationClient
        self.resourceFactory = resourceFactory
        self.clock = clock
        self.configuration = configuration
        self.metricConverter = metricConverter
        self.delegateBridge = delegateBridge

        super.init()
        self.delegateBridge.delegate = self
    }

    deinit {
        continuation.finish()
    }

    // MARK: - WorkoutProviding

    func authorizationStatus() async -> WorkoutAuthorizationStatus {
        guard await authorizationClient.isHealthDataAvailable() else {
            return .unavailable
        }

        do {
            let status = try await authorizationClient.authorizationRequestStatus(
                toShare: HealthKitDataTypes.typesToShare,
                read: HealthKitDataTypes.typesToRead
            )
            switch status {
            case .shouldRequest:
                return .notDetermined
            case .unnecessary:
                return .authorized
            case .unknown:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
        } catch {
            return .notDetermined
        }
    }

    func requestAuthorization() async throws {
        guard await authorizationClient.isHealthDataAvailable() else {
            continuation.yield(.authorizationChanged(.unavailable))
            throw WorkoutServiceFailure.healthDataUnavailable
        }

        state = .authorizing
        do {
            try await authorizationClient.requestAuthorization(
                toShare: HealthKitDataTypes.typesToShare,
                read: HealthKitDataTypes.typesToRead
            )
            state = .idle
            continuation.yield(.authorizationChanged(.authorized))
        } catch {
            state = .failed
            continuation.yield(.failed(.authorizationFailed))
            throw WorkoutServiceFailure.authorizationFailed
        }
    }

    func prepare() async throws {
        guard state == .idle || state == .ended || state == .failed else {
            throw WorkoutServiceFailure.invalidServiceState
        }

        let auth = await authorizationStatus()
        guard auth == .authorized else {
            state = .failed
            continuation.yield(.failed(.authorizationDenied))
            throw WorkoutServiceFailure.authorizationDenied
        }

        state = .preparing
        do {
            let resources = try resourceFactory.createResources(
                configuration: configuration,
                delegateBridge: delegateBridge
            )
            self.session = resources.session
            self.builder = resources.builder

            session?.prepare()
            state = .ready
            continuation.yield(.stateChanged(.prepared))
            continuation.yield(.stateChanged(.ready))
        } catch {
            state = .failed
            continuation.yield(.failed(.preparationFailed))
            throw WorkoutServiceFailure.preparationFailed
        }
    }

    func start(at date: Date) async throws {
        guard state == .prepared || state == .ready, let session, let builder else {
            throw WorkoutServiceFailure.invalidServiceState
        }

        state = .starting
        continuation.yield(.stateChanged(.starting))

        do {
            try await builder.beginCollection(at: date)
            session.startActivity(at: date)
            state = .running
            continuation.yield(.stateChanged(.running))
        } catch {
            state = .failed
            continuation.yield(.failed(.startFailed))
            throw WorkoutServiceFailure.startFailed
        }
    }

    func pause() async throws {
        guard state == .running, let session else {
            throw WorkoutServiceFailure.invalidServiceState
        }

        state = .pausing
        session.pause()
        state = .paused
        continuation.yield(.stateChanged(.paused))
    }

    func resume() async throws {
        guard state == .paused, let session else {
            throw WorkoutServiceFailure.invalidServiceState
        }

        state = .resuming
        session.resume()
        state = .running
        continuation.yield(.stateChanged(.running))
    }

    func finish(at date: Date) async throws {
        guard state == .running || state == .paused, let session, let builder else {
            throw WorkoutServiceFailure.invalidServiceState
        }

        state = .stopping
        continuation.yield(.stateChanged(.stopping))
        continuation.yield(.finalizationStarted)

        session.stopActivity(at: date)

        state = .finalizing
        continuation.yield(.stateChanged(.finalizing))

        do {
            try await builder.endCollection(at: date)
            let completedWorkout = try await builder.finishWorkout()
            session.end()

            state = .ended
            continuation.yield(.workoutSaved(completedWorkout))
            continuation.yield(.stateChanged(.ended))
        } catch {
            state = .failed
            continuation.yield(.failed(.finishFailed))
            throw WorkoutServiceFailure.finishFailed
        }
    }

    func cancel() async {
        session?.end()
        session = nil
        builder = nil
        state = .idle
        continuation.yield(.stateChanged(.idle))
    }

    func reset() async {
        guard state == .ended || state == .failed || state == .idle else {
            return
        }

        session = nil
        builder = nil
        state = .idle
        continuation.yield(.stateChanged(.idle))
    }

    // MARK: - HealthKitDelegateBridgeDelegate

    func workoutSessionChanged(
        to newState: HKWorkoutSessionState,
        from oldState: HKWorkoutSessionState,
        at date: Date
    ) {
        switch newState {
        case .notStarted:
            break
        case .prepared:
            if state == .preparing {
                state = .prepared
                continuation.yield(.stateChanged(.prepared))
            }
        case .running:
            state = .running
            continuation.yield(.stateChanged(.running))
        case .paused:
            state = .paused
            continuation.yield(.stateChanged(.paused))
        case .stopped:
            if state == .running || state == .paused {
                state = .stopping
                continuation.yield(.stateChanged(.stopping))
            }
        case .ended:
            if state != .ended && state != .idle {
                state = .ended
                continuation.yield(.stateChanged(.ended))
            }
        @unknown default:
            break
        }
    }

    func workoutSessionFailed(_ error: Error) {
        state = .failed
        continuation.yield(.failed(.unexpected))
    }

    func workoutBuilderCollected(statisticsFor types: Set<HKSampleType>) {
        guard let builder else { return }
        let timestamp = clock.now

        for type in types {
            guard let quantityType = type as? HKQuantityType else { continue }
            guard let stats = builder.statistics(for: quantityType) else { continue }
            guard let metric = metricConverter.metric(for: quantityType, statistics: stats, timestamp: timestamp) else { continue }

            continuation.yield(.metricReceived(metric))

            switch metric {
            case .heartRate(let bpm, let time):
                continuation.yield(.heartRateReceived(beatsPerMinute: Int(bpm), timestamp: time))
            case .activeEnergy(let kcal, let time):
                continuation.yield(.activeEnergyReceived(kilocalories: kcal, timestamp: time))
            case .cyclingDistance(let meters, let time):
                continuation.yield(.distanceReceived(meters: meters, timestamp: time))
            }
        }
    }

    func workoutBuilderCollectedEvent() {}
}
