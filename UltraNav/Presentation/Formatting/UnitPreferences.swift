import Foundation

/// User preferences for unit representations.
public struct UnitPreferences: Equatable, Sendable {
    public enum DistanceSystem: String, Codable, Sendable {
        case metric
        case imperial
    }

    public let distanceSystem: DistanceSystem

    public init(distanceSystem: DistanceSystem = .metric) {
        self.distanceSystem = distanceSystem
    }

    public static let metric = UnitPreferences(distanceSystem: .metric)
    public static let imperial = UnitPreferences(distanceSystem: .imperial)
    public static let `default` = UnitPreferences.metric
}
