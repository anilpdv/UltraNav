import Foundation

@MainActor
final class MetricsEngine: MetricsEngineProviding {
    private(set) var currentSnapshot: MetricsSnapshot
    private let snapshotChannel = AsyncEventChannel<MetricsSnapshot>(bufferingPolicy: .bufferingNewest(5))
    var snapshots: AsyncStream<MetricsSnapshot> {
        snapshotChannel.makeStream()
    }

    private let validator: any MetricValidating
    private let arbitrator: any MetricArbitrating
    private let freshnessEvaluator: any MetricFreshnessEvaluating
    private let configuration: MetricsConfiguration
    private let clock: any ClockProviding
    private let summaryBuilder: RideSummaryBuilder

    private(set) var state: MetricsEngineState = .idle
    private(set) var recordingState: MetricsRecordingState = .idle

    // Candidate observation storage: [MetricKind: [MetricSource: MetricObservation]]
    private var observations: [MetricKind: [MetricSource: MetricObservation]] = [:]
    private var selections: [MetricKind: MetricSelection] = [:]
    private var recoveryState: [MetricKind: Date] = [:]

    // Trackers and Accumulators
    private var distanceTracker = CumulativeMetricTracker()
    private var energyTracker = CumulativeMetricTracker()
    private var movingAccumulator = MovingMetricAccumulator()

    private var speedAverage = TimeWeightedAverage()
    private var speedMax = MaximumAccumulator()
    private var heartRateAverage = TimeWeightedAverage()
    private var heartRateMax = MaximumAccumulator()
    private var cadenceAverage = TimeWeightedAverage()
    private var cadenceMax = MaximumAccumulator()
    private var powerAverage = TimeWeightedAverage()
    private var powerMax = MaximumAccumulator()

    private var powerSmoother = PowerSmoother()
    private var normalizedPowerAccumulator = NormalizedPowerAccumulator()
    private let ifCalculator = IntensityFactorCalculator()
    private let tssCalculator = TrainingStressScoreCalculator()
    private var lapEngine = LapEngine()

    // Diagnostic Counters
    private var sourceTransitionCount: Int = 0
    private var rejectedObservationCount: Int = 0
    private var rideStartedAt: Date?
    private var rideFinishedAt: Date?
    private var finishedSummary: RideMetricsSummary?

    init(
        validator: any MetricValidating = StandardMetricValidator(),
        arbitrator: any MetricArbitrating = MetricArbitrator(),
        freshnessEvaluator: any MetricFreshnessEvaluating = MetricFreshnessEvaluator(),
        configuration: MetricsConfiguration = .outdoorCycling,
        clock: any ClockProviding = SystemClock(),
        summaryBuilder: RideSummaryBuilder = RideSummaryBuilder()
    ) {
        self.validator = validator
        self.arbitrator = arbitrator
        self.freshnessEvaluator = freshnessEvaluator
        self.configuration = configuration
        self.clock = clock
        self.summaryBuilder = summaryBuilder
        self.currentSnapshot = .empty
    }

    func send(_ command: MetricsEngineCommand) async {
        let now = clock.now

        switch command {
        case .start(let at):
            let start = at ?? now
            state = .active
            recordingState = .recording(startedAt: start)
            rideStartedAt = start
            rideFinishedAt = nil
            finishedSummary = nil

            distanceTracker.reset()
            energyTracker.reset()
            movingAccumulator.reset()
            movingAccumulator.start(at: start)

            speedAverage.reset()
            speedMax.reset()
            heartRateAverage.reset()
            heartRateMax.reset()
            cadenceAverage.reset()
            cadenceMax.reset()
            powerAverage.reset()
            powerMax.reset()
            powerSmoother.reset()
            normalizedPowerAccumulator.reset()
            normalizedPowerAccumulator.start(at: start)

            lapEngine.reset()
            lapEngine.startRide(at: start, distanceMeters: 0)

            sourceTransitionCount = 0
            rejectedObservationCount = 0

            publishSnapshot(at: start)

        case .pause(let at):
            guard state == .active, case .recording(let start) = recordingState else { return }
            let pauseDate = at ?? now
            state = .paused
            recordingState = .paused(startedAt: start, pausedAt: pauseDate)

            movingAccumulator.pause(at: pauseDate)
            lapEngine.pause(at: pauseDate)
            distanceTracker.rebase(afterPauseAt: pauseDate)
            energyTracker.rebase(afterPauseAt: pauseDate)

            speedAverage.stop(at: pauseDate)
            heartRateAverage.stop(at: pauseDate)
            cadenceAverage.stop(at: pauseDate)
            powerAverage.stop(at: pauseDate)

            publishSnapshot(at: pauseDate)

        case .resume(let at):
            guard state == .paused, case .paused(let start, _) = recordingState else { return }
            let resumeDate = at ?? now
            state = .active
            recordingState = .recording(startedAt: start)

            movingAccumulator.resume(at: resumeDate)
            lapEngine.resume(at: resumeDate)
            distanceTracker.rebase(afterPauseAt: resumeDate)
            energyTracker.rebase(afterPauseAt: resumeDate)

            publishSnapshot(at: resumeDate)

        case .stop(let at), .finish(let at):
            guard state == .active || state == .paused else { return }
            let finishDate = at ?? now
            let start = rideStartedAt ?? finishDate
            state = .stopped
            recordingState = .finished(startedAt: start, finishedAt: finishDate)
            rideFinishedAt = finishDate

            movingAccumulator.finish(at: finishDate)
            speedAverage.stop(at: finishDate)
            heartRateAverage.stop(at: finishDate)
            cadenceAverage.stop(at: finishDate)
            powerAverage.stop(at: finishDate)

            let dist = distanceTracker.displayedTotal
            _ = lapEngine.finishRide(at: finishDate, distanceMeters: dist)

            // Compute final power metrics
            let np = normalizedPowerAccumulator.normalizedPowerWatts
            let ftp = configuration.power.functionalThresholdPowerWatts.flatMap { FunctionalThresholdPower(watts: $0) }
            let ifVal = ifCalculator.calculate(normalizedPowerWatts: np, ftp: ftp)
            let tss = tssCalculator.calculate(
                eligibleDurationSeconds: movingAccumulator.activeTimeSeconds,
                normalizedPowerWatts: np,
                intensityFactor: ifVal,
                ftp: ftp
            )

            let avgActiveSpeed: Double? = movingAccumulator.activeTimeSeconds > 0
                ? (dist / movingAccumulator.activeTimeSeconds)
                : nil
            let avgMovingSpeed: Double? = movingAccumulator.movingTimeSeconds > 0
                ? (dist / movingAccumulator.movingTimeSeconds)
                : nil

            let quality = RideMetricsDataQuality(
                speedCoverageRatio: movingAccumulator.activeTimeSeconds > 0 ? min(1.0, speedAverage.totalDurationSeconds / movingAccumulator.activeTimeSeconds) : 0,
                heartRateCoverageRatio: movingAccumulator.activeTimeSeconds > 0 ? min(1.0, heartRateAverage.totalDurationSeconds / movingAccumulator.activeTimeSeconds) : 0,
                cadenceCoverageRatio: movingAccumulator.activeTimeSeconds > 0 ? min(1.0, cadenceAverage.totalDurationSeconds / movingAccumulator.activeTimeSeconds) : 0,
                powerCoverageRatio: movingAccumulator.activeTimeSeconds > 0 ? min(1.0, powerAverage.totalDurationSeconds / movingAccumulator.activeTimeSeconds) : 0,
                gpsDistanceAvailable: observations[.cumulativeDistance]?[.gps] != nil,
                wheelDistanceAvailable: observations[.cumulativeDistance]?.keys.contains {
                    if case .bluetooth = $0 { return true }
                    return false
                } ?? false,
                sourceTransitionCount: sourceTransitionCount,
                rejectedObservationCount: rejectedObservationCount
            )

            finishedSummary = summaryBuilder.build(
                startedAt: start,
                finishedAt: finishDate,
                elapsedTimeSeconds: movingAccumulator.elapsedTimeSeconds,
                activeTimeSeconds: movingAccumulator.activeTimeSeconds,
                movingTimeSeconds: movingAccumulator.movingTimeSeconds,
                distanceMeters: dist,
                averageActiveSpeed: avgActiveSpeed,
                averageMovingSpeed: avgMovingSpeed,
                maxSpeed: speedMax.maximum,
                averageHeartRate: heartRateAverage.average,
                maxHeartRate: heartRateMax.maximum,
                averageCadence: cadenceAverage.average,
                maxCadence: cadenceMax.maximum,
                averagePower: powerAverage.average,
                maxPower: powerMax.maximum,
                normalizedPower: np,
                intensityFactor: ifVal,
                trainingStressScore: tss,
                activeEnergyKilocalories: energyTracker.displayedTotal > 0 ? energyTracker.displayedTotal : nil,
                laps: lapEngine.completedLaps,
                dataQuality: quality
            )

            publishSnapshot(at: finishDate)

        case .createManualLap(let at):
            let lapDate = at ?? now
            _ = lapEngine.createLap(
                trigger: .manual,
                at: lapDate,
                distanceMeters: distanceTracker.displayedTotal
            )
            publishSnapshot(at: lapDate)

        case .reset:
            state = .idle
            recordingState = .idle
            rideStartedAt = nil
            rideFinishedAt = nil
            finishedSummary = nil

            observations.removeAll()
            selections.removeAll()
            recoveryState.removeAll()

            distanceTracker.reset()
            energyTracker.reset()
            movingAccumulator.reset()
            speedAverage.reset()
            speedMax.reset()
            heartRateAverage.reset()
            heartRateMax.reset()
            cadenceAverage.reset()
            cadenceMax.reset()
            powerAverage.reset()
            powerMax.reset()
            powerSmoother.reset()
            normalizedPowerAccumulator.reset()
            lapEngine.reset()

            sourceTransitionCount = 0
            rejectedObservationCount = 0

            currentSnapshot = .empty
            snapshotChannel.send(.empty)
        }
    }

    func consume(_ input: MetricsInput) {
        switch input {
        case .location(let sample):
            consume(location: sample)
        case .gps(let accepted):
            consume(gps: accepted)
        case .workout(let metric):
            consume(workout: metric)
        case .sensor(let id, let sample):
            consume(sensor: id, sample: sample)
        case .tick(let date):
            handleTick(at: date)
        }
    }

    func consume(gps: GPSAcceptedSample) {
        let now = clock.now

        if let speed = gps.selectedSpeedMetersPerSecond {
            let obs = MetricObservation(
                kind: .speed,
                value: .speedMetersPerSecond(speed),
                source: .gps,
                measuredAt: gps.sample.timestamp,
                receivedAt: now
            )
            processObservation(obs, at: now)
        }

        let distObs = MetricObservation(
            kind: .cumulativeDistance,
            value: .cumulativeDistanceMeters(gps.totalDistanceMeters),
            source: .gps,
            measuredAt: gps.sample.timestamp,
            receivedAt: now
        )
        processObservation(distObs, at: now)

        if let altitude = gps.sample.altitudeMeters {
            let altObs = MetricObservation(
                kind: .altitude,
                value: .altitudeMeters(altitude),
                source: .gps,
                measuredAt: gps.sample.timestamp,
                receivedAt: now
            )
            processObservation(altObs, at: now)
        }
    }

    func consume(location: LocationSample) {
        let now = clock.now

        if let speed = location.speedMetersPerSecond {
            let obs = MetricObservation(
                kind: .speed,
                value: .speedMetersPerSecond(speed),
                source: .gps,
                measuredAt: location.timestamp,
                receivedAt: now
            )
            processObservation(obs, at: now)
        }

        if let altitude = location.altitudeMeters {
            let obs = MetricObservation(
                kind: .altitude,
                value: .altitudeMeters(altitude),
                source: .gps,
                measuredAt: location.timestamp,
                receivedAt: now
            )
            processObservation(obs, at: now)
        }
    }

    func consume(workout: WorkoutMetric) {
        let now = clock.now

        switch workout {
        case .heartRate(let bpm, let timestamp):
            let obs = MetricObservation(
                kind: .heartRate,
                value: .heartRateBeatsPerMinute(bpm),
                source: .healthKit,
                measuredAt: timestamp,
                receivedAt: now
            )
            processObservation(obs, at: now)

        case .activeEnergy(let kcal, let timestamp):
            let obs = MetricObservation(
                kind: .activeEnergy,
                value: .cumulativeActiveEnergyKilocalories(kcal),
                source: .healthKit,
                measuredAt: timestamp,
                receivedAt: now
            )
            processObservation(obs, at: now)

        case .cyclingDistance(let meters, let timestamp):
            let obs = MetricObservation(
                kind: .cumulativeDistance,
                value: .cumulativeDistanceMeters(meters),
                source: .healthKit,
                measuredAt: timestamp,
                receivedAt: now
            )
            processObservation(obs, at: now)
        }
    }

    func consume(sensor: SensorIdentifier, sample: SensorSample) {
        let now = clock.now
        let source = MetricSource.bluetooth(sensor: sensor)

        switch sample {
        case .heartRate(let bpm, let ts):
            let obs = MetricObservation(
                kind: .heartRate,
                value: .heartRateBeatsPerMinute(Double(bpm)),
                source: source,
                measuredAt: ts,
                receivedAt: now
            )
            processObservation(obs, at: now)

        case .power(let watts, let ts):
            let obs = MetricObservation(
                kind: .power,
                value: .powerWatts(Double(watts)),
                source: source,
                measuredAt: ts,
                receivedAt: now
            )
            processObservation(obs, at: now)

        case .cadence(let rpm, let ts):
            let obs = MetricObservation(
                kind: .cadence,
                value: .cadenceRevolutionsPerMinute(rpm),
                source: source,
                measuredAt: ts,
                receivedAt: now
            )
            processObservation(obs, at: now)

        case .speed(let mps, let ts):
            let obs = MetricObservation(
                kind: .speed,
                value: .speedMetersPerSecond(mps),
                source: source,
                measuredAt: ts,
                receivedAt: now
            )
            processObservation(obs, at: now)
        }
    }

    private func processObservation(_ observation: MetricObservation, at date: Date) {
        // 1. Validation
        let valResult = validator.validate(observation, policy: configuration.validation)
        guard case .accepted(let validObs) = valResult else {
            rejectedObservationCount += 1
            return
        }

        let kind = validObs.kind

        // 2. Store latest candidate observation for (kind, source)
        if observations[kind] == nil {
            observations[kind] = [:]
        }
        observations[kind]?[validObs.source] = validObs

        // 3. Source Arbitration
        let candidates = Array(observations[kind]?.values ?? [:].values)
        let currentSel = selections[kind]
        let result = arbitrator.select(
            kind: kind,
            candidates: candidates,
            currentSelection: currentSel,
            policy: configuration.sourcePolicy,
            freshnessEvaluator: freshnessEvaluator,
            freshnessConfig: configuration.freshness,
            at: date,
            recoveryState: &recoveryState
        )

        if let trans = result.transition {
            sourceTransitionCount += 1
            _ = trans
        }

        selections[kind] = result.selection

        // 4. Update Aggregation if recording and this observation comes from selected source
        let isRecording = (state == .active)
        let isPaused = (state == .paused)

        if let sel = result.selection, sel.source == validObs.source {
            switch validObs.value {
            case .speedMetersPerSecond(let spd):
                if isRecording {
                    speedAverage.consume(value: spd, at: date, maximumIntervalSeconds: configuration.freshness.speedSeconds)
                    speedMax.consume(spd)
                }
            case .cumulativeDistanceMeters(let rawDist):
                if isRecording {
                    distanceTracker.selectSource(validObs.source, currentRawValue: rawDist, at: date)
                    _ = distanceTracker.consume(source: validObs.source, rawValue: rawDist, at: date)
                }
            case .heartRateBeatsPerMinute(let hr):
                if isRecording {
                    heartRateAverage.consume(value: hr, at: date, maximumIntervalSeconds: configuration.freshness.heartRateSeconds)
                    heartRateMax.consume(hr)
                }
            case .cadenceRevolutionsPerMinute(let cad):
                if isRecording {
                    cadenceAverage.consume(value: cad, at: date, maximumIntervalSeconds: configuration.freshness.cadenceSeconds)
                    cadenceMax.consume(cad)
                }
            case .powerWatts(let pwr):
                powerSmoother.consume(watts: pwr, at: date)
                if isRecording {
                    powerAverage.consume(value: pwr, at: date, maximumIntervalSeconds: configuration.freshness.powerSeconds)
                    powerMax.consume(pwr)
                    normalizedPowerAccumulator.consume(watts: pwr, at: date)
                }
            case .cumulativeActiveEnergyKilocalories(let rawKcal):
                if isRecording {
                    energyTracker.selectSource(validObs.source, currentRawValue: rawKcal, at: date)
                    _ = energyTracker.consume(source: validObs.source, rawValue: rawKcal, at: date)
                }
            case .altitudeMeters:
                break
            }

            lapEngine.consume(
                observation: validObs,
                at: date,
                isPaused: isPaused,
                currentSpeed: selections[.speed]?.observation.value.doubleValue
            )
        }

        publishSnapshot(at: date)
    }

    private func handleTick(at date: Date) {
        guard state == .active || state == .paused else { return }

        let isPaused = (state == .paused)
        let currentSpeed = selections[.speed]?.observation.value.doubleValue
        movingAccumulator.tick(at: date, isPaused: isPaused, currentSpeedMetersPerSecond: currentSpeed)
        lapEngine.tick(at: date, isPaused: isPaused, currentSpeed: currentSpeed)

        publishSnapshot(at: date)
    }

    private func publishSnapshot(at date: Date) {
        // Build live power metrics
        let currentPowerWatts = selections[.power]?.observation.value.doubleValue
        let pwrAvail = selections[.power].map {
            freshnessEvaluator.availability(
                kind: .power,
                measuredAt: $0.observation.measuredAt,
                currentDate: date,
                configuration: configuration.freshness
            )
        } ?? .unavailable

        let np = normalizedPowerAccumulator.normalizedPowerWatts
        let ftp = configuration.power.functionalThresholdPowerWatts.flatMap { FunctionalThresholdPower(watts: $0) }
        let ifVal = ifCalculator.calculate(normalizedPowerWatts: np, ftp: ftp)
        let tss = tssCalculator.calculate(
            eligibleDurationSeconds: movingAccumulator.activeTimeSeconds,
            normalizedPowerWatts: np,
            intensityFactor: ifVal,
            ftp: ftp
        )

        let pwrSnapshot = PowerMetricsSnapshot(
            currentWatts: currentPowerWatts,
            threeSecondWatts: powerSmoother.average(windowSeconds: 3.0, at: date),
            tenSecondWatts: powerSmoother.average(windowSeconds: 10.0, at: date),
            thirtySecondWatts: powerSmoother.average(windowSeconds: 30.0, at: date),
            averageWatts: powerAverage.average,
            maximumWatts: powerMax.maximum,
            normalizedPowerWatts: np,
            intensityFactor: ifVal,
            trainingStressScore: tss,
            source: selections[.power]?.source,
            availability: pwrAvail
        )

        // Build CurrentMetric items
        let speedObs: CurrentMetric<Double>? = selections[.speed].map { sel in
            let avail = freshnessEvaluator.availability(
                kind: .speed,
                measuredAt: sel.observation.measuredAt,
                currentDate: date,
                configuration: configuration.freshness
            )
            return CurrentMetric(
                value: sel.observation.value.doubleValue,
                source: sel.source,
                timestamp: sel.observation.measuredAt,
                freshness: MetricFreshnessState(from: avail)
            )
        }

        let hrObs: CurrentMetric<Int>? = selections[.heartRate].map { sel in
            let avail = freshnessEvaluator.availability(
                kind: .heartRate,
                measuredAt: sel.observation.measuredAt,
                currentDate: date,
                configuration: configuration.freshness
            )
            return CurrentMetric(
                value: Int(sel.observation.value.doubleValue.rounded()),
                source: sel.source,
                timestamp: sel.observation.measuredAt,
                freshness: MetricFreshnessState(from: avail)
            )
        }

        let cadObs: CurrentMetric<Double>? = selections[.cadence].map { sel in
            let avail = freshnessEvaluator.availability(
                kind: .cadence,
                measuredAt: sel.observation.measuredAt,
                currentDate: date,
                configuration: configuration.freshness
            )
            return CurrentMetric(
                value: sel.observation.value.doubleValue,
                source: sel.source,
                timestamp: sel.observation.measuredAt,
                freshness: MetricFreshnessState(from: avail)
            )
        }

        let pwrObs: CurrentMetric<Int>? = selections[.power].map { sel in
            return CurrentMetric(
                value: Int(sel.observation.value.doubleValue.rounded()),
                source: sel.source,
                timestamp: sel.observation.measuredAt,
                freshness: MetricFreshnessState(from: pwrAvail)
            )
        }

        let distObs: CurrentMetric<Double>? = {
            let total = distanceTracker.displayedTotal
            guard let sel = selections[.cumulativeDistance] else {
                return total > 0 ? CurrentMetric(value: total, source: .gps, timestamp: date) : nil
            }
            let avail = freshnessEvaluator.availability(
                kind: .cumulativeDistance,
                measuredAt: sel.observation.measuredAt,
                currentDate: date,
                configuration: configuration.freshness
            )
            return CurrentMetric(
                value: total,
                source: sel.source,
                timestamp: sel.observation.measuredAt,
                freshness: MetricFreshnessState(from: avail)
            )
        }()

        let altObs: CurrentMetric<Double>? = selections[.altitude].map { sel in
            let avail = freshnessEvaluator.availability(
                kind: .altitude,
                measuredAt: sel.observation.measuredAt,
                currentDate: date,
                configuration: configuration.freshness
            )
            return CurrentMetric(
                value: sel.observation.value.doubleValue,
                source: sel.source,
                timestamp: sel.observation.measuredAt,
                freshness: MetricFreshnessState(from: avail)
            )
        }

        let energyObs: CurrentMetric<Double>? = {
            let total = energyTracker.displayedTotal
            guard let sel = selections[.activeEnergy] else {
                return total > 0 ? CurrentMetric(value: total, source: .healthKit, timestamp: date) : nil
            }
            let avail = freshnessEvaluator.availability(
                kind: .activeEnergy,
                measuredAt: sel.observation.measuredAt,
                currentDate: date,
                configuration: configuration.freshness
            )
            return CurrentMetric(
                value: total,
                source: sel.source,
                timestamp: sel.observation.measuredAt,
                freshness: MetricFreshnessState(from: avail)
            )
        }()

        let snapshot = MetricsSnapshot(
            speed: speedObs,
            heartRate: hrObs,
            cadence: cadObs,
            power: pwrObs,
            distance: distObs,
            altitude: altObs,
            energy: energyObs,
            averageSpeedMetersPerSecond: speedAverage.average,
            maxSpeedMetersPerSecond: speedMax.maximum,
            averageHeartRateBeatsPerMinute: heartRateAverage.average.map { Int($0.rounded()) },
            maxHeartRateBeatsPerMinute: heartRateMax.maximum.map { Int($0.rounded()) },
            averageCadenceRevolutionsPerMinute: cadenceAverage.average,
            averagePowerWatts: powerAverage.average.map { Int($0.rounded()) },
            maxPowerWatts: powerMax.maximum.map { Int($0.rounded()) },
            normalizedPowerWatts: np.map { Int($0.rounded()) },
            intensityFactor: ifVal,
            trainingStressScore: tss,
            totalKilocalories: energyTracker.displayedTotal > 0 ? energyTracker.displayedTotal : nil,
            elapsedTimeSeconds: movingAccumulator.elapsedTimeSeconds,
            activeTimeSeconds: movingAccumulator.activeTimeSeconds,
            movingTimeSeconds: movingAccumulator.movingTimeSeconds,
            powerMetrics: pwrSnapshot,
            laps: lapEngine.completedLaps,
            summary: finishedSummary,
            timestamp: date
        )

        self.currentSnapshot = snapshot
        snapshotChannel.send(snapshot)
    }
}
