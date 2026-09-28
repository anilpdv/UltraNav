import Foundation

struct SensorMeasurementPacket: Equatable, Sendable {
    let sensor: SensorIdentifier
    let serviceIdentifier: String
    let characteristicIdentifier: String
    let payload: Data
    let receivedAt: Date
}
