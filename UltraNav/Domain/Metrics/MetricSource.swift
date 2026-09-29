import Foundation

enum MetricSource: Hashable, Sendable {
    case coreLocation
    case healthKit
    case bluetooth(sensorID: SensorIdentifier)
    case derived
}
