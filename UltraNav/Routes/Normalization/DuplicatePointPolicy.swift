import Foundation

/// Policy defining how duplicate route vertices are detected and pruned.
public enum DuplicatePointPolicy: Equatable, Sendable {
    case preserveAll
    case removeExactConsecutiveCoordinates
    case removeExactConsecutiveSamples
    case removeNearDuplicates(distanceMeters: Double)
}
