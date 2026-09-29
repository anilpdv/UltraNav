import Foundation

/// Continuous elevation profile along a route with ascent/descent aggregates.
struct ElevationProfile: Equatable, Sendable, Codable {
    let routeID: Route.ID
    let points: [ElevationProfilePoint]
    let totalAscentMeters: Double
    let totalDescentMeters: Double
    let minElevationMeters: Double
    let maxElevationMeters: Double

    var totalDistanceMeters: Double {
        points.last?.distanceMeters ?? 0
    }

    var elevationRangeMeters: Double {
        max(0, maxElevationMeters - minElevationMeters)
    }

    init(
        routeID: Route.ID,
        points: [ElevationProfilePoint],
        totalAscentMeters: Double,
        totalDescentMeters: Double,
        minElevationMeters: Double,
        maxElevationMeters: Double
    ) {
        self.routeID = routeID
        self.points = points
        self.totalAscentMeters = totalAscentMeters
        self.totalDescentMeters = totalDescentMeters
        self.minElevationMeters = minElevationMeters
        self.maxElevationMeters = maxElevationMeters
    }

    init(
        routeID: UUID,
        points: [ElevationProfilePoint],
        totalAscentMeters: Double,
        totalDescentMeters: Double,
        minElevationMeters: Double,
        maxElevationMeters: Double
    ) {
        self.init(
            routeID: RouteID(uuid: routeID),
            points: points,
            totalAscentMeters: totalAscentMeters,
            totalDescentMeters: totalDescentMeters,
            minElevationMeters: minElevationMeters,
            maxElevationMeters: maxElevationMeters
        )
    }
}
