import Foundation

struct MetricStore: Sendable {
    var latestSpeedObservation: MetricObservation?
    var latestHeartRateObservation: MetricObservation?
    var latestCadenceObservation: MetricObservation?
    var latestPowerObservation: MetricObservation?
    var latestDistanceObservation: MetricObservation?
    var latestAltitudeObservation: MetricObservation?
    var latestEnergyObservation: MetricObservation?

    var speedBuffer = RollingSampleBuffer(capacity: 300)
    var heartRateBuffer = RollingSampleBuffer(capacity: 300)
    var cadenceBuffer = RollingSampleBuffer(capacity: 300)
    var powerBuffer = RollingSampleBuffer(capacity: 300)

    var accumulatedDistanceMeters: Double = 0.0
    var totalEnergyKilocalories: Double = 0.0

    mutating func reset() {
        latestSpeedObservation = nil
        latestHeartRateObservation = nil
        latestCadenceObservation = nil
        latestPowerObservation = nil
        latestDistanceObservation = nil
        latestAltitudeObservation = nil
        latestEnergyObservation = nil

        speedBuffer.clear()
        heartRateBuffer.clear()
        cadenceBuffer.clear()
        powerBuffer.clear()

        accumulatedDistanceMeters = 0.0
        totalEnergyKilocalories = 0.0
    }

    mutating func store(observation: MetricObservation) {
        switch observation.value {
        case .speed:
            latestSpeedObservation = observation
            speedBuffer.append(observation)
        case .heartRate:
            latestHeartRateObservation = observation
            heartRateBuffer.append(observation)
        case .cadence:
            latestCadenceObservation = observation
            cadenceBuffer.append(observation)
        case .power:
            latestPowerObservation = observation
            powerBuffer.append(observation)
        case .distance(let meters):
            latestDistanceObservation = observation
            accumulatedDistanceMeters = max(accumulatedDistanceMeters, meters)
        case .altitude:
            latestAltitudeObservation = observation
        case .energy(let kcal):
            latestEnergyObservation = observation
            totalEnergyKilocalories = max(totalEnergyKilocalories, kcal)
        }
    }
}
