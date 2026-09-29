import Foundation

struct MetricsSnapshot: Equatable, Sendable {
    let speed: CurrentMetric<Double>?
    let heartRate: CurrentMetric<Int>?
    let cadence: CurrentMetric<Double>?
    let power: CurrentMetric<Int>?
    let distance: CurrentMetric<Double>?
    let altitude: CurrentMetric<Double>?
    let energy: CurrentMetric<Double>?

    let averageSpeedMetersPerSecond: Double?
    let maxSpeedMetersPerSecond: Double?
    let averageHeartRateBeatsPerMinute: Int?
    let maxHeartRateBeatsPerMinute: Int?
    let averageCadenceRevolutionsPerMinute: Double?
    let averagePowerWatts: Int?
    let maxPowerWatts: Int?
    let normalizedPowerWatts: Int?
    let intensityFactor: Double?
    let trainingStressScore: Double?
    let totalKilocalories: Double?

    let elapsedTimeSeconds: TimeInterval
    let activeTimeSeconds: TimeInterval
    let movingTimeSeconds: TimeInterval

    let powerMetrics: PowerMetricsSnapshot
    let laps: [LapRecord]
    let summary: RideMetricsSummary?
    let timestamp: Date

    var availability: MetricGroupAvailability {
        MetricGroupAvailability(
            hasSpeed: speed != nil && speed?.freshness != .expired,
            hasHeartRate: heartRate != nil && heartRate?.freshness != .expired,
            hasCadence: cadence != nil && cadence?.freshness != .expired,
            hasPower: power != nil && power?.freshness != .expired,
            hasDistance: distance != nil && distance?.freshness != .expired,
            hasAltitude: altitude != nil && altitude?.freshness != .expired,
            hasEnergy: energy != nil && energy?.freshness != .expired
        )
    }

    init(
        speed: CurrentMetric<Double>? = nil,
        heartRate: CurrentMetric<Int>? = nil,
        cadence: CurrentMetric<Double>? = nil,
        power: CurrentMetric<Int>? = nil,
        distance: CurrentMetric<Double>? = nil,
        altitude: CurrentMetric<Double>? = nil,
        energy: CurrentMetric<Double>? = nil,
        averageSpeedMetersPerSecond: Double? = nil,
        maxSpeedMetersPerSecond: Double? = nil,
        averageHeartRateBeatsPerMinute: Int? = nil,
        maxHeartRateBeatsPerMinute: Int? = nil,
        averageCadenceRevolutionsPerMinute: Double? = nil,
        averagePowerWatts: Int? = nil,
        maxPowerWatts: Int? = nil,
        normalizedPowerWatts: Int? = nil,
        intensityFactor: Double? = nil,
        trainingStressScore: Double? = nil,
        totalKilocalories: Double? = nil,
        elapsedTimeSeconds: TimeInterval = 0,
        activeTimeSeconds: TimeInterval = 0,
        movingTimeSeconds: TimeInterval = 0,
        powerMetrics: PowerMetricsSnapshot = .empty,
        laps: [LapRecord] = [],
        summary: RideMetricsSummary? = nil,
        timestamp: Date = Date()
    ) {
        self.speed = speed
        self.heartRate = heartRate
        self.cadence = cadence
        self.power = power
        self.distance = distance
        self.altitude = altitude
        self.energy = energy
        self.averageSpeedMetersPerSecond = averageSpeedMetersPerSecond
        self.maxSpeedMetersPerSecond = maxSpeedMetersPerSecond
        self.averageHeartRateBeatsPerMinute = averageHeartRateBeatsPerMinute
        self.maxHeartRateBeatsPerMinute = maxHeartRateBeatsPerMinute
        self.averageCadenceRevolutionsPerMinute = averageCadenceRevolutionsPerMinute
        self.averagePowerWatts = averagePowerWatts
        self.maxPowerWatts = maxPowerWatts
        self.normalizedPowerWatts = normalizedPowerWatts
        self.intensityFactor = intensityFactor
        self.trainingStressScore = trainingStressScore
        self.totalKilocalories = totalKilocalories
        self.elapsedTimeSeconds = elapsedTimeSeconds
        self.activeTimeSeconds = activeTimeSeconds
        self.movingTimeSeconds = movingTimeSeconds
        self.powerMetrics = powerMetrics
        self.laps = laps
        self.summary = summary
        self.timestamp = timestamp
    }

    static let empty = MetricsSnapshot(
        speed: nil,
        heartRate: nil,
        cadence: nil,
        power: nil,
        distance: nil,
        altitude: nil,
        energy: nil,
        averageSpeedMetersPerSecond: nil,
        maxSpeedMetersPerSecond: nil,
        averageHeartRateBeatsPerMinute: nil,
        maxHeartRateBeatsPerMinute: nil,
        averageCadenceRevolutionsPerMinute: nil,
        averagePowerWatts: nil,
        maxPowerWatts: nil,
        normalizedPowerWatts: nil,
        intensityFactor: nil,
        trainingStressScore: nil,
        totalKilocalories: nil,
        elapsedTimeSeconds: 0,
        activeTimeSeconds: 0,
        movingTimeSeconds: 0,
        powerMetrics: .empty,
        laps: [],
        summary: nil,
        timestamp: Date()
    )
}
