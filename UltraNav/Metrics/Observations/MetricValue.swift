import Foundation

enum MetricValue: Equatable, Sendable {
    case speedMetersPerSecond(Double)
    case cumulativeDistanceMeters(Double)
    case heartRateBeatsPerMinute(Double)
    case cadenceRevolutionsPerMinute(Double)
    case powerWatts(Double)
    case cumulativeActiveEnergyKilocalories(Double)
    case altitudeMeters(Double)

    var doubleValue: Double {
        switch self {
        case .speedMetersPerSecond(let v): return v
        case .cumulativeDistanceMeters(let v): return v
        case .heartRateBeatsPerMinute(let v): return v
        case .cadenceRevolutionsPerMinute(let v): return v
        case .powerWatts(let v): return v
        case .cumulativeActiveEnergyKilocalories(let v): return v
        case .altitudeMeters(let v): return v
        }
    }

    var kind: MetricKind {
        switch self {
        case .speedMetersPerSecond: return .speed
        case .cumulativeDistanceMeters: return .cumulativeDistance
        case .heartRateBeatsPerMinute: return .heartRate
        case .cadenceRevolutionsPerMinute: return .cadence
        case .powerWatts: return .power
        case .cumulativeActiveEnergyKilocalories: return .activeEnergy
        case .altitudeMeters: return .altitude
        }
    }
}
