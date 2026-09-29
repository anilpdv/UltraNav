import Foundation

enum MetricSourcePreference: Equatable, Hashable, Sendable {
    case gps
    case healthKit
    case bluetoothHeartRate
    case bluetoothPower
    case bluetoothPowerCadence
    case bluetoothCSC
    case bluetoothWheel
    case specificSensor(SensorIdentifier)

    func matches(source: MetricSource, kind: MetricKind) -> Bool {
        switch (self, source) {
        case (.gps, .gps):
            return true
        case (.healthKit, .healthKit):
            return true
        case (.bluetoothHeartRate, .bluetooth):
            return kind == .heartRate
        case (.bluetoothPower, .bluetooth):
            return kind == .power
        case (.bluetoothPowerCadence, .bluetooth):
            return kind == .cadence
        case (.bluetoothCSC, .bluetooth):
            return kind == .cadence || kind == .speed || kind == .cumulativeDistance
        case (.bluetoothWheel, .bluetooth):
            return kind == .speed || kind == .cumulativeDistance
        case (.specificSensor(let expectedId), .bluetooth(let actualId)):
            return expectedId == actualId
        default:
            return false
        }
    }
}

struct MetricSourcePolicy: Equatable, Sendable {
    let speed: [MetricSourcePreference]
    let distance: [MetricSourcePreference]
    let heartRate: [MetricSourcePreference]
    let cadence: [MetricSourcePreference]
    let power: [MetricSourcePreference]
    let activeEnergy: [MetricSourcePreference]
    let altitude: [MetricSourcePreference]
    let switchBackDelaySeconds: TimeInterval

    func preferences(for kind: MetricKind) -> [MetricSourcePreference] {
        switch kind {
        case .speed: return speed
        case .cumulativeDistance: return distance
        case .heartRate: return heartRate
        case .cadence: return cadence
        case .power: return power
        case .activeEnergy: return activeEnergy
        case .altitude: return altitude
        case .elapsedTime, .activeTime, .movingTime: return []
        }
    }

    static let outdoorCycling = MetricSourcePolicy(
        speed: [
            .bluetoothWheel,
            .gps,
            .healthKit
        ],
        distance: [
            .bluetoothWheel,
            .gps,
            .healthKit
        ],
        heartRate: [
            .bluetoothHeartRate,
            .healthKit
        ],
        cadence: [
            .bluetoothPowerCadence,
            .bluetoothCSC
        ],
        power: [
            .bluetoothPower
        ],
        activeEnergy: [
            .healthKit
        ],
        altitude: [
            .gps
        ],
        switchBackDelaySeconds: 3.0
    )
}
