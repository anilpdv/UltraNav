import Foundation

struct SensorScanRequest: Equatable, Sendable {
    let sensorTypes: Set<SensorType>
    let allowDuplicateDiscoveries: Bool

    static func standard(for sensorTypes: Set<SensorType>) -> SensorScanRequest {
        SensorScanRequest(
            sensorTypes: sensorTypes,
            allowDuplicateDiscoveries: false
        )
    }
}
