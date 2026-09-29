import Foundation

enum MetricSource: Equatable, Hashable, Codable, Sendable {
    case gps
    case healthKit
    case bluetooth(sensor: SensorIdentifier)
    case manual
    case derived

    // Compatibility / convenience for legacy coreLocation references
    static var coreLocation: MetricSource {
        .gps
    }

    static func bluetooth(sensorID: SensorIdentifier) -> MetricSource {
        .bluetooth(sensor: sensorID)
    }
}
