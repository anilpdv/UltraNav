import Foundation

@MainActor
final class MetricsEngine: MetricsEngineProviding {
    private(set) var currentSnapshot: MetricsSnapshot
    let snapshots: AsyncStream<MetricsSnapshot>
    private let snapshotContinuation: AsyncStream<MetricsSnapshot>.Continuation

    private let validator: any MetricValidating
    private let sourceSelector: any MetricSourceSelecting
    private let summaryBuilder: MetricsSummaryBuilder
    private let clock: any ClockProviding

    private(set) var state: MetricsEngineState = .idle
    private var store = MetricStore()

    init(
        validator: any MetricValidating = StandardMetricValidator(),
        sourceSelector: any MetricSourceSelecting = TemporaryLatestSourceSelector(),
        summaryBuilder: MetricsSummaryBuilder = MetricsSummaryBuilder(),
        clock: any ClockProviding = SystemClock()
    ) {
        let pair = AsyncStream.makeStream(
            of: MetricsSnapshot.self,
            bufferingPolicy: .bufferingNewest(5)
        )
        self.snapshots = pair.stream
        self.snapshotContinuation = pair.continuation

        self.validator = validator
        self.sourceSelector = sourceSelector
        self.summaryBuilder = summaryBuilder
        self.clock = clock

        self.currentSnapshot = .empty
    }

    deinit {
        snapshotContinuation.finish()
    }

    func send(_ command: MetricsEngineCommand) async {
        switch command {
        case .start(let at):
            state = .active
            publishSnapshot(at: at ?? clock.now)

        case .pause(let at):
            guard state == .active else { return }
            state = .paused
            publishSnapshot(at: at ?? clock.now)

        case .resume(let at):
            guard state == .paused else { return }
            state = .active
            publishSnapshot(at: at ?? clock.now)

        case .stop(let at), .finish(let at):
            state = .stopped
            publishSnapshot(at: at ?? clock.now)

        case .reset:
            state = .idle
            store.reset()
            currentSnapshot = .empty
            snapshotContinuation.yield(.empty)
        }
    }

    func consume(_ input: MetricsInput) {
        switch input {
        case .location(let sample):
            consume(location: sample)
        case .workout(let metric):
            consume(workout: metric)
        case .sensor(let id, let sample):
            consume(sensor: id, sample: sample)
        }
    }

    func consume(location: LocationSample) {
        guard state == .active else { return }

        let now = clock.now

        if let speed = location.speedMetersPerSecond {
            let obs = MetricObservation(source: .coreLocation, value: .speed(metersPerSecond: speed), timestamp: location.timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }
        }

        if let altitude = location.altitudeMeters {
            let obs = MetricObservation(source: .coreLocation, value: .altitude(meters: altitude), timestamp: location.timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }
        }

        publishSnapshot(at: now)
    }

    func consume(workout: WorkoutMetric) {
        guard state == .active else { return }

        let now = clock.now

        switch workout {
        case .heartRate(let bpm, let timestamp):
            let obs = MetricObservation(source: .healthKit, value: .heartRate(beatsPerMinute: Int(bpm.rounded())), timestamp: timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }

        case .activeEnergy(let kcal, let timestamp):
            let obs = MetricObservation(source: .healthKit, value: .energy(kilocalories: kcal), timestamp: timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }

        case .cyclingDistance(let meters, let timestamp):
            let obs = MetricObservation(source: .healthKit, value: .distance(meters: meters), timestamp: timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }
        }

        publishSnapshot(at: now)
    }

    func consume(sensor: SensorIdentifier, sample: SensorSample) {
        guard state == .active else { return }

        let now = clock.now
        let source = MetricSource.bluetooth(sensorID: sensor)

        switch sample {
        case .heartRate(let bpm, let timestamp):
            let obs = MetricObservation(source: source, value: .heartRate(beatsPerMinute: bpm), timestamp: timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }

        case .power(let watts, let timestamp):
            let obs = MetricObservation(source: source, value: .power(watts: watts), timestamp: timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }

        case .cadence(let rpm, let timestamp):
            let obs = MetricObservation(source: source, value: .cadence(revolutionsPerMinute: rpm), timestamp: timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }

        case .speed(let mps, let timestamp):
            let obs = MetricObservation(source: source, value: .speed(metersPerSecond: mps), timestamp: timestamp)
            if validator.validate(observation: obs) {
                store.store(observation: obs)
            }
        }

        publishSnapshot(at: now)
    }

    private func publishSnapshot(at date: Date? = nil) {
        let now = date ?? clock.now
        let snapshot = summaryBuilder.makeSnapshot(store: store, now: now)

        guard snapshot != currentSnapshot else { return }
        currentSnapshot = snapshot
        snapshotContinuation.yield(snapshot)
    }
}
