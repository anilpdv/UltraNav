import Foundation

enum MetricSemantics: String, Codable, Equatable, Sendable {
    case instantaneous
    case cumulative
    case derived

    static func semantics(for kind: MetricKind) -> MetricSemantics {
        switch kind {
        case .speed, .heartRate, .cadence, .power, .altitude:
            return .instantaneous
        case .cumulativeDistance, .activeEnergy:
            return .cumulative
        case .elapsedTime, .activeTime, .movingTime:
            return .derived
        }
    }
}
