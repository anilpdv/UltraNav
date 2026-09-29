import Foundation

/// Protocol isolating great-circle/ellipsoidal distance computation between geographic coordinates.
public protocol CoordinateDistanceCalculating: Sendable {
    func distance(from: Coordinate, to: Coordinate) -> Double
}
