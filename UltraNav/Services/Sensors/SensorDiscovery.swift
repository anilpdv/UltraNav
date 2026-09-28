import Foundation

struct SensorDiscovery: Equatable, Sendable {
    let descriptor: SensorDescriptor
    let signalStrength: Int?
    let advertisedName: String?
    let discoveredAt: Date
}
