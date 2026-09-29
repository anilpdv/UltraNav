import Foundation

struct MetricFreshness: Equatable, Sendable {
    let speedSeconds: TimeInterval
    let heartRateSeconds: TimeInterval
    let cadenceSeconds: TimeInterval
    let powerSeconds: TimeInterval
    let altitudeSeconds: TimeInterval
    let cumulativeDistanceSeconds: TimeInterval
    let activeEnergySeconds: TimeInterval

    func timeout(for kind: MetricKind) -> TimeInterval {
        switch kind {
        case .speed: return speedSeconds
        case .heartRate: return heartRateSeconds
        case .cadence: return cadenceSeconds
        case .power: return powerSeconds
        case .altitude: return altitudeSeconds
        case .cumulativeDistance: return cumulativeDistanceSeconds
        case .activeEnergy: return activeEnergySeconds
        case .elapsedTime, .activeTime, .movingTime: return .infinity
        }
    }

    static let standard = MetricFreshness(
        speedSeconds: 5.0,
        heartRateSeconds: 10.0,
        cadenceSeconds: 5.0,
        powerSeconds: 3.0,
        altitudeSeconds: 10.0,
        cumulativeDistanceSeconds: 15.0,
        activeEnergySeconds: 30.0
    )
}
