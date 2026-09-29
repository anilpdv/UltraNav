import Foundation
import OSLog

@MainActor
final class RideEngine: RideEngineProviding, RideLocationConsuming {
    var currentSnapshot: RideSnapshot {
        snapshotBuilder.makeSnapshot(
            state: stateMachine.state,
            timing: timingState,
            metrics: metricState,
            locationStatus: locationStatus,
            workoutStatus: workoutStatus,
            sensorStatus: sensorStatus,
            degradations: degradations,
            activeFailure: activeFailure,
            now: clock.now
        )
    }
    private var lastPublishedSnapshot: RideSnapshot = .initial
    let snapshots: AsyncStream<RideSnapshot>
    private let snapshotContinuation: AsyncStream<RideSnapshot>.Continuation

    let location: any LocationProviding
    let workout: any WorkoutProviding
    let sensors: any SensorProviding
    let clock: any ClockProviding
    let dependencyPolicy: RideDependencyPolicy

    private(set) var stateMachine: RideStateMachine
    private(set) var timingState: RideTimingState
    private(set) var metricState: RideMetricState

    private(set) var locationStatus: RideLocationStatus
    private(set) var workoutStatus: RideWorkoutStatus
    private(set) var sensorStatus: RideSensorStatus
    private(set) var degradations: RideDegradation
    private(set) var activeFailure: RideFailure?

    private var sensorConnectionStates: [SensorIdentifier: SensorConnectionState] = [:]
    private var consumerTasks: [Task<Void, Never>] = []
    private var commandInProgress: RideEngineCommand?

    private let snapshotBuilder: RideSnapshotBuilder
    private let failureMapper: RideFailureMapper

    init(
        location: any LocationProviding,
        workout: any WorkoutProviding,
        sensors: any SensorProviding,
        clock: any ClockProviding,
        dependencyPolicy: RideDependencyPolicy = .outdoorCycling,
        snapshotBuilder: RideSnapshotBuilder = RideSnapshotBuilder(),
        failureMapper: RideFailureMapper = RideFailureMapper()
    ) {
        let pair = AsyncStream.makeStream(
            of: RideSnapshot.self,
            bufferingPolicy: .bufferingNewest(5)
        )
        self.snapshots = pair.stream
        self.snapshotContinuation = pair.continuation

        self.location = location
        self.workout = workout
        self.sensors = sensors
        self.clock = clock
        self.dependencyPolicy = dependencyPolicy
        self.snapshotBuilder = snapshotBuilder
        self.failureMapper = failureMapper

        self.stateMachine = RideStateMachine()
        self.timingState = RideTimingState()
        self.metricState = RideMetricState()

        self.locationStatus = .unavailable
        self.workoutStatus = .unavailable
        self.sensorStatus = .empty
        self.degradations = []
        self.activeFailure = nil
    }

    deinit {
        for task in consumerTasks {
            task.cancel()
        }
        snapshotContinuation.finish()
    }

    // MARK: - Lifecycle Activation & Shutdown

    func activate() {
        guard consumerTasks.isEmpty else {
            return
        }
        startLocationEventConsumer()
        startWorkoutEventConsumer()
        startSensorEventConsumer()
    }

    func shutdown() async {
        for task in consumerTasks {
            task.cancel()
        }
        consumerTasks.removeAll()

        await location.stopUpdates()
        await sensors.stopScanning()

        snapshotContinuation.finish()
    }

    // MARK: - Command Dispatch

    func send(_ command: RideEngineCommand) async {
        guard commandInProgress == nil else {
            return
        }

        commandInProgress = command
        defer {
            commandInProgress = nil
        }

        switch command {
        case .prepare:
            await prepare()

        case .start:
            await start()

        case .pause:
            await pause()

        case .resume:
            await resume()

        case .finish:
            await finish()

        case .recover:
            await recover()

        case .reset:
            await reset()
        }
    }

    // MARK: - Command Implementations

    private func prepare() async {
        activate()

        do {
            let transition = try stateMachine.handle(.prepareRequested)
            await apply(transition)
        } catch {
            return
        }
    }

    private func prepareDependencies() async {
        locationStatus = .preparing
        workoutStatus = .preparing
        publishSnapshot()

        do {
            if dependencyPolicy.requiresLocation {
                try await prepareLocation()
            }

            if dependencyPolicy.requiresWorkout {
                try await prepareWorkout()
            }

            locationStatus = .ready
            workoutStatus = .ready

            let transition = try stateMachine.handle(.preparationSucceeded)
            await apply(transition)
        } catch let failure as RideFailure {
            await failPreparation(failure)
        } catch {
            await failPreparation(.unexpected)
        }
    }

    private func prepareLocation() async throws {
        let status = await location.authorizationStatus()

        switch status {
        case .authorized:
            locationStatus = .ready

        case .notDetermined:
            await location.requestAuthorization()
            throw RideFailure.locationPermissionRequired

        case .denied:
            throw RideFailure.locationPermissionDenied

        case .restricted:
            throw RideFailure.locationUnavailable
        }
    }

    private func prepareWorkout() async throws {
        let status = await workout.authorizationStatus()

        switch status {
        case .authorized:
            break

        case .notDetermined:
            try await workout.requestAuthorization()

        case .denied:
            throw RideFailure.workoutAuthorizationDenied

        case .unavailable:
            throw RideFailure.workoutPreparationFailed
        }

        do {
            try await workout.prepare()
        } catch {
            throw RideFailure.workoutPreparationFailed
        }
    }

    private func failPreparation(_ failure: RideFailure) async {
        await rollbackPreparation()
        activeFailure = failure
        let transition = try? stateMachine.handle(.preparationFailed(failure))
        if let transition {
            await apply(transition)
        } else {
            publishSnapshot()
        }
    }

    private func rollbackPreparation() async {
        await location.stopUpdates()
        await workout.reset()

        locationStatus = .unavailable
        workoutStatus = .unavailable
    }

    private func start() async {
        do {
            let transition = try stateMachine.handle(.startRequested)
            await apply(transition)
        } catch {
            return
        }
    }

    private func startDependencies() async {
        let startDate = clock.now

        do {
            do {
                try await workout.start(at: startDate)
            } catch {
                throw RideFailure.workoutStartFailed
            }

            do {
                try await location.startUpdates()
            } catch {
                await rollbackPartialStart(at: clock.now)
                throw RideFailure.locationUnavailable
            }

            if dependencyPolicy.allowsRideWithoutSensors {
                try? await sensors.startScanning(for: [.cyclingPower, .heartRate, .cyclingCadence, .cyclingSpeed])
            }

            timingState.start(at: startDate)
            workoutStatus = .active
            locationStatus = .active

            let transition = try stateMachine.handle(.startSucceeded)
            await apply(transition)
        } catch let failure as RideFailure {
            await handleStartFailure(failure)
        } catch {
            await handleStartFailure(.workoutStartFailed)
        }
    }

    private func handleStartFailure(_ failure: RideFailure) async {
        activeFailure = failure
        let transition = try? stateMachine.handle(.startFailed(failure))
        if let transition {
            await apply(transition)
        } else {
            publishSnapshot()
        }
    }

    private func rollbackPartialStart(at date: Date) async {
        await location.stopUpdates()
        await workout.cancel()

        workoutStatus = .failed
        locationStatus = .failed
    }

    private func pause() async {
        do {
            let transition = try stateMachine.handle(.pauseRequested)
            await apply(transition)
        } catch {
            return
        }
    }

    private func pauseDependencies() async {
        do {
            try await workout.pause()

            let pauseDate = clock.now
            timingState.pause(at: pauseDate)
            workoutStatus = .paused

            let transition = try stateMachine.handle(.pauseSucceeded)
            await apply(transition)
        } catch {
            activeFailure = .workoutPauseFailed
            let transition = try? stateMachine.handle(.pauseFailed(.workoutPauseFailed))
            if let transition {
                await apply(transition)
            }
        }
    }

    private func resume() async {
        do {
            let transition = try stateMachine.handle(.resumeRequested)
            await apply(transition)
        } catch {
            return
        }
    }

    private func resumeDependencies() async {
        do {
            try await workout.resume()

            let resumeDate = clock.now
            timingState.resume(at: resumeDate)
            workoutStatus = .active

            let transition = try stateMachine.handle(.resumeSucceeded)
            await apply(transition)
        } catch {
            activeFailure = .workoutResumeFailed
            let transition = try? stateMachine.handle(.resumeFailed(.workoutResumeFailed))
            if let transition {
                await apply(transition)
            }
        }
    }

    private func finish() async {
        do {
            let transition = try stateMachine.handle(.finishRequested)
            await apply(transition)
        } catch {
            if case .failed(_, .retryFinishing) = stateMachine.state {
                await recover()
            }
        }
    }

    private func finishDependencies() async {
        let finishDate = clock.now

        locationStatus = .ready
        workoutStatus = .finalizing
        publishSnapshot()

        await location.stopUpdates()
        await sensors.stopScanning()

        do {
            try await workout.finish(at: finishDate)

            timingState.finish(at: finishDate)
            workoutStatus = .ended

            let transition = try stateMachine.handle(.finishSucceeded)
            await apply(transition)
        } catch {
            timingState.finish(at: finishDate)
            workoutStatus = .failed
            activeFailure = .workoutFinishFailed

            let transition = try? stateMachine.handle(.finishFailed(.workoutFinishFailed))
            if let transition {
                await apply(transition)
            }
        }
    }

    private func recover() async {
        do {
            let transition = try stateMachine.handle(.recoveryRequested)
            activeFailure = nil
            await apply(transition)
        } catch {
            return
        }
    }

    private func reset() async {
        do {
            let transition = try stateMachine.handle(.resetRequested)
            await apply(transition)
        } catch {
            return
        }
    }

    private func resetDependencies() async {
        await location.stopUpdates()
        await sensors.stopScanning()
        await workout.reset()

        timingState.reset()
        metricState.reset()

        locationStatus = .unavailable
        workoutStatus = .unavailable
        sensorStatus = .empty
        degradations = []
        activeFailure = nil
        sensorConnectionStates.removeAll()

        publishSnapshot()
    }

    // MARK: - State Machine Effect Interpretation

    private func apply(_ transition: RideTransition) async {
        publishSnapshot()

        for effect in transition.effects {
            switch effect {
            case .prepareDependencies:
                await prepareDependencies()

            case .startRide:
                await startDependencies()

            case .pauseRide:
                await pauseDependencies()

            case .resumeRide:
                await resumeDependencies()

            case .finishRide:
                await finishDependencies()

            case .resetRide:
                await resetDependencies()
            }
        }
    }

    // MARK: - Event Consumers

    private func startLocationEventConsumer() {
        let events = location.events

        let task = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled else { break }
                self?.handle(locationEvent: event)
            }
        }
        consumerTasks.append(task)
    }

    private func startWorkoutEventConsumer() {
        let events = workout.events

        let task = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled else { break }
                self?.handle(workoutEvent: event)
            }
        }
        consumerTasks.append(task)
    }

    private func startSensorEventConsumer() {
        let events = sensors.events

        let task = Task { [weak self] in
            for await event in events {
                guard !Task.isCancelled else { break }
                self?.handle(sensorEvent: event)
            }
        }
        consumerTasks.append(task)
    }

    func handle(locationEvent: LocationServiceEvent) {
        switch locationEvent {
        case .authorizationChanged(let status):
            if status == .denied || status == .restricted {
                degradations.insert(.locationUnavailable)
                if stateMachine.state.hasActiveRideSession && dependencyPolicy.requiresLocation {
                    locationStatus = .failed
                }
            }

        case .updateStarted:
            locationStatus = .active

        case .locationReceived(let sample):
            guard stateMachine.state.acceptsLocationSamples else { return }
            metricState.consume(location: sample)

        case .updateStopped:
            if stateMachine.state == .completed {
                locationStatus = .ready
            } else {
                locationStatus = .unavailable
            }

        case .failed:
            degradations.insert(.locationUnavailable)
            if stateMachine.state.hasActiveRideSession {
                locationStatus = .failed
            }
        }

        publishSnapshot()
    }

    private func handle(workoutEvent: WorkoutServiceEvent) {
        switch workoutEvent {
        case .authorizationChanged:
            break

        case .stateChanged(let ws):
            switch ws {
            case .idle, .authorizing:
                workoutStatus = .unavailable
            case .preparing:
                workoutStatus = .preparing
            case .prepared, .ready:
                workoutStatus = .ready
            case .starting, .running, .resuming:
                workoutStatus = .active
            case .pausing, .paused:
                workoutStatus = .paused
            case .stopping, .finalizing, .ending:
                workoutStatus = .finalizing
            case .ended:
                workoutStatus = .ended
            case .failed:
                workoutStatus = .failed
            }

        case .heartRateReceived(let bpm, _):
            guard stateMachine.state.hasActiveRideSession else { return }
            metricState.consumeHeartRate(bpm)

        case .activeEnergyReceived:
            break

        case .distanceReceived(let meters, _):
            guard stateMachine.state.hasActiveRideSession else { return }
            metricState.consumeDistance(meters)

        case .metricReceived(let metric):
            guard stateMachine.state.hasActiveRideSession else { return }
            metricState.consume(workout: metric)

        case .finalizationStarted:
            workoutStatus = .finalizing

        case .workoutSaved:
            workoutStatus = .ended

        case .failed(let failure):
            degradations.insert(.workoutMetricsUnavailable)
            if stateMachine.state.hasActiveRideSession {
                workoutStatus = .failed
                activeFailure = failureMapper.map(failure)
            }
        }

        publishSnapshot()
    }

    private func handle(sensorEvent: SensorServiceEvent) {
        switch sensorEvent {
        case .availabilityChanged(let availability):
            sensorStatus = RideSensorStatus(
                bluetoothAvailable: availability == .poweredOn,
                connectedSensorCount: sensorStatus.connectedSensorCount,
                readySensorCount: sensorStatus.readySensorCount
            )

        case .connectionStateChanged(let id, let state):
            updateSensorState(id: id, state: state)

        case .sensorReady(let descriptor):
            updateSensorState(id: descriptor.id, state: .ready)

        case .sampleReceived(_, let sample):
            guard stateMachine.state.hasActiveRideSession else { return }
            metricState.consume(sensor: sample)

        case .scanStateChanged,
             .sensorDiscovered:
            break

        case .failed:
            degradations.insert(.sensorsUnavailable)
        }

        publishSnapshot()
    }

    private func updateSensorState(id: SensorIdentifier, state: SensorConnectionState) {
        sensorConnectionStates[id] = state

        let connected = sensorConnectionStates.values.filter {
            switch $0 {
            case .connected,
                 .discoveringServices,
                 .discoveringCharacteristics,
                 .subscribing,
                 .ready:
                return true
            default:
                return false
            }
        }.count

        let ready = sensorConnectionStates.values.filter {
            $0 == .ready
        }.count

        sensorStatus = RideSensorStatus(
            bluetoothAvailable: sensorStatus.bluetoothAvailable,
            connectedSensorCount: connected,
            readySensorCount: ready
        )
    }

    // MARK: - Metrics Processing

    func consume(metrics: MetricsSnapshot) {
        if let speed = metrics.speed?.value {
            metricState.currentSpeedMetersPerSecond = speed
        }
        if let distance = metrics.distance?.value {
            metricState.distanceMeters = distance
        }
        if let hr = metrics.heartRate?.value {
            metricState.heartRateBeatsPerMinute = hr
        }
        if let cadence = metrics.cadence?.value {
            metricState.cadenceRevolutionsPerMinute = cadence
        }
        if let power = metrics.power?.value {
            metricState.powerWatts = power
        }
        if let altitude = metrics.altitude?.value {
            metricState.altitudeMeters = altitude
        }

        publishSnapshot()
    }

    // MARK: - Snapshot Publication

    func publishSnapshot() {
        let snapshot = currentSnapshot
        guard snapshot != lastPublishedSnapshot else { return }
        lastPublishedSnapshot = snapshot
        snapshotContinuation.yield(snapshot)
    }
}
