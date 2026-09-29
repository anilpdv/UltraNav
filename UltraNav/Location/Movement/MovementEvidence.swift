import Foundation

/// Evidence vector evaluated for movement classification.
public struct MovementEvidence: Equatable, Sendable {
    public let selectedSpeedMetersPerSecond: Double?
    public let positionDistanceMeters: Double
    public let accuracyOverlap: Bool
    public let timeDeltaSeconds: TimeInterval

    public init(
        selectedSpeedMetersPerSecond: Double?,
        positionDistanceMeters: Double,
        accuracyOverlap: Bool,
        timeDeltaSeconds: TimeInterval
    ) {
        self.selectedSpeedMetersPerSecond = selectedSpeedMetersPerSecond
        self.positionDistanceMeters = positionDistanceMeters
        self.accuracyOverlap = accuracyOverlap
        self.timeDeltaSeconds = timeDeltaSeconds
    }
}
