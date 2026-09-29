import Foundation

enum NavigationRouteValidationFailure: Error, Equatable, Sendable {
    case insufficientPoints
    case invalidCoordinate
    case invalidTotalDistance
    case invalidCumulativeDistance
    case nonMonotonicDistance
}

protocol NavigationRouteValidating: Sendable {
    func validate(_ route: Route) throws
}

struct NavigationRouteValidator: NavigationRouteValidating, Sendable {
    func validate(_ route: Route) throws {
        guard route.points.count >= 2 else {
            throw NavigationRouteValidationFailure.insufficientPoints
        }

        guard route.totalDistanceMeters.isFinite,
              route.totalDistanceMeters > 0 else {
            throw NavigationRouteValidationFailure.invalidTotalDistance
        }

        var previousDistance = 0.0

        for point in route.points {
            guard point.coordinate.isGeographicallyValid else {
                throw NavigationRouteValidationFailure.invalidCoordinate
            }

            let distance = point.cumulativeDistanceMeters

            guard distance.isFinite,
                  distance >= 0 else {
                throw NavigationRouteValidationFailure.invalidCumulativeDistance
            }

            guard distance >= previousDistance else {
                throw NavigationRouteValidationFailure.nonMonotonicDistance
            }

            previousDistance = distance
        }
    }
}
