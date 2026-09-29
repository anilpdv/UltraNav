import Foundation

/// Type-safe, deterministic route identifier.
public struct RouteID: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible, Identifiable {
    public let rawValue: String

    public var id: String { rawValue }

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(uuid: UUID) {
        self.rawValue = uuid.uuidString
    }

    public init(sha256Hex: String) {
        self.rawValue = "route-v1:\(sha256Hex)"
    }
}
