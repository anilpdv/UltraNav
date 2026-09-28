import Foundation

struct SensorIdentifier: RawRepresentable,
                         Hashable,
                         Codable,
                         Sendable {
    let rawValue: String

    init(rawValue: String) {
        self.rawValue = rawValue
    }
}
