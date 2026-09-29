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
    let totalKilocalories: Double?

    let availability: MetricAvailability
    let timestamp: Date

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
        totalKilocalories: Double? = nil,
        availability: MetricAvailability = .empty,
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
        self.totalKilocalories = totalKilocalories
        self.availability = availability
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
        totalKilocalories: nil,
        availability: .empty,
        timestamp: Date()
    )
}
