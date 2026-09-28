import Foundation

struct RideSensorStatus: Equatable, Sendable {
    let bluetoothAvailable: Bool
    let connectedSensorCount: Int
    let readySensorCount: Int

    static let empty = RideSensorStatus(
        bluetoothAvailable: false,
        connectedSensorCount: 0,
        readySensorCount: 0
    )
}
