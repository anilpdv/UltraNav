import Foundation
import CoreLocation

/// Default implementation of CoordinateDistanceCalculating using CLLocation.
public final class CoreLocationDistanceCalculator: CoordinateDistanceCalculating, Sendable {
    public init() {}

    public func distance(from: Coordinate, to: Coordinate) -> Double {
        let loc1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let loc2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return loc2.distance(from: loc1)
    }
}
