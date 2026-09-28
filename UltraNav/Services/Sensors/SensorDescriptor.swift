import Foundation

struct SensorDescriptor: Identifiable,
                         Equatable,
                         Hashable,
                         Sendable {
    let id: SensorIdentifier
    let name: String?
    let supportedTypes: Set<SensorType>
    let isRemembered: Bool
}
