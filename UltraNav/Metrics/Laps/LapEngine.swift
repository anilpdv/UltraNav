import Foundation

struct LapEngine: Sendable {
    private(set) var currentLapNumber: Int = 1
    private(set) var currentLapStartedAt: Date?
    private(set) var currentLapStartDistanceMeters: Double = 0
    private(set) var completedLaps: [LapRecord] = []

    private var lapSpeedAverage = TimeWeightedAverage()
    private var lapHeartRateAverage = TimeWeightedAverage()
    private var lapHeartRateMax = MaximumAccumulator()
    private var lapCadenceAverage = TimeWeightedAverage()
    private var lapPowerAverage = TimeWeightedAverage()
    private var lapPowerMax = MaximumAccumulator()
    private var lapNPAccumulator = NormalizedPowerAccumulator()
    private var lapMovingAccumulator = MovingMetricAccumulator()

    private let configuration: LapConfiguration

    init(configuration: LapConfiguration = .standard) {
        self.configuration = configuration
    }

    mutating func startRide(at date: Date, distanceMeters: Double = 0) {
        currentLapNumber = 1
        currentLapStartedAt = date
        currentLapStartDistanceMeters = distanceMeters
        completedLaps.removeAll()

        lapMovingAccumulator.start(at: date)
        lapNPAccumulator.start(at: date)
        resetLapAccumulators()
    }

    mutating func consume(
        observation: MetricObservation,
        at date: Date,
        isPaused: Bool,
        currentSpeed: Double? = nil
    ) {
        lapMovingAccumulator.tick(at: date, isPaused: isPaused, currentSpeedMetersPerSecond: currentSpeed)

        guard !isPaused else { return }

        switch observation.value {
        case .speedMetersPerSecond(let spd):
            lapSpeedAverage.consume(value: spd, at: date, maximumIntervalSeconds: 5.0)
        case .heartRateBeatsPerMinute(let hr):
            lapHeartRateAverage.consume(value: hr, at: date, maximumIntervalSeconds: 10.0)
            lapHeartRateMax.consume(hr)
        case .cadenceRevolutionsPerMinute(let cad):
            lapCadenceAverage.consume(value: cad, at: date, maximumIntervalSeconds: 5.0)
        case .powerWatts(let pwr):
            lapPowerAverage.consume(value: pwr, at: date, maximumIntervalSeconds: 3.0)
            lapPowerMax.consume(pwr)
            lapNPAccumulator.consume(watts: pwr, at: date)
        case .cumulativeDistanceMeters, .cumulativeActiveEnergyKilocalories, .altitudeMeters:
            break
        }
    }

    mutating func tick(at date: Date, isPaused: Bool, currentSpeed: Double?) {
        lapMovingAccumulator.tick(at: date, isPaused: isPaused, currentSpeedMetersPerSecond: currentSpeed)
    }

    mutating func pause(at date: Date) {
        lapMovingAccumulator.pause(at: date)
        lapSpeedAverage.stop(at: date)
        lapHeartRateAverage.stop(at: date)
        lapCadenceAverage.stop(at: date)
        lapPowerAverage.stop(at: date)
    }

    mutating func resume(at date: Date) {
        lapMovingAccumulator.resume(at: date)
    }

    mutating func createLap(
        trigger: LapTrigger,
        at date: Date,
        distanceMeters: Double
    ) -> LapRecord? {
        guard let start = currentLapStartedAt else { return nil }
        let duration = max(0, date.timeIntervalSince(start))
        let lapDistance = max(0, distanceMeters - currentLapStartDistanceMeters)

        // Check minimal threshold for manual laps if applicable
        if case .manual = trigger {
            if duration < configuration.minimumLapDurationSeconds && lapDistance < configuration.minimumLapDistanceMeters && !completedLaps.isEmpty {
                return nil
            }
        }

        lapMovingAccumulator.finish(at: date)
        lapSpeedAverage.stop(at: date)
        lapHeartRateAverage.stop(at: date)
        lapCadenceAverage.stop(at: date)
        lapPowerAverage.stop(at: date)

        let summary = LapMetricsSummary(
            elapsedTimeSeconds: lapMovingAccumulator.elapsedTimeSeconds,
            activeTimeSeconds: lapMovingAccumulator.activeTimeSeconds,
            movingTimeSeconds: lapMovingAccumulator.movingTimeSeconds,
            distanceMeters: lapDistance,
            averageSpeedMetersPerSecond: lapSpeedAverage.average,
            averageHeartRateBPM: lapHeartRateAverage.average,
            maximumHeartRateBPM: lapHeartRateMax.maximum,
            averageCadenceRPM: lapCadenceAverage.average,
            averagePowerWatts: lapPowerAverage.average,
            maximumPowerWatts: lapPowerMax.maximum,
            normalizedPowerWatts: lapNPAccumulator.normalizedPowerWatts
        )

        let record = LapRecord(
            id: LapRecord.ID(rawValue: currentLapNumber),
            number: currentLapNumber,
            trigger: trigger,
            startedAt: start,
            endedAt: date,
            startDistanceMeters: currentLapStartDistanceMeters,
            endDistanceMeters: distanceMeters,
            summary: summary
        )

        completedLaps.append(record)

        // Start next lap
        currentLapNumber += 1
        currentLapStartedAt = date
        currentLapStartDistanceMeters = distanceMeters

        lapMovingAccumulator.reset()
        lapMovingAccumulator.start(at: date)
        lapNPAccumulator.reset()
        lapNPAccumulator.start(at: date)
        resetLapAccumulators()

        return record
    }

    mutating func finishRide(at date: Date, distanceMeters: Double) -> LapRecord? {
        return createLap(trigger: .manual, at: date, distanceMeters: distanceMeters)
    }

    mutating func reset() {
        currentLapNumber = 1
        currentLapStartedAt = nil
        currentLapStartDistanceMeters = 0
        completedLaps.removeAll()
        lapMovingAccumulator.reset()
        lapNPAccumulator.reset()
        resetLapAccumulators()
    }

    private mutating func resetLapAccumulators() {
        lapSpeedAverage.reset()
        lapHeartRateAverage.reset()
        lapHeartRateMax.reset()
        lapCadenceAverage.reset()
        lapPowerAverage.reset()
        lapPowerMax.reset()
    }
}
