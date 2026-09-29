import Foundation
@testable import UltraNav

/// Standardized canonical Route fixtures covering straight, turn, loop, and elevation profiles.
enum RouteFixture {
    /// Creates a straight north-bound route of specified distance and points.
    static func straightRoute(
        id: Route.ID = TestIDs.routeAlpha,
        name: String = "Straight Route",
        distanceMeters: Double = 1000.0,
        pointCount: Int = 10
    ) -> Route {
        var points: [RoutePoint] = []
        let deltaLat = 0.001
        for index in 0..<pointCount {
            let lat = 24.7136 + Double(index) * deltaLat
            let lon = 46.6753
            let dist = (Double(index) / Double(pointCount - 1)) * distanceMeters
            points.append(RoutePoint(
                coordinate: Coordinate(latitude: lat, longitude: lon),
                elevationMeters: 600.0 + Double(index) * 2.0,
                timestamp: TestDates.rideStart.addingTimeInterval(Double(index) * 10),
                cumulativeDistanceMeters: dist
            ))
        }

        let bounds = RouteBounds(
            minimumLatitude: 24.7136,
            maximumLatitude: 24.7136 + Double(pointCount - 1) * deltaLat,
            minimumLongitude: 46.6753,
            maximumLongitude: 46.6753
        )

        let metadata = RouteMetadata(
            name: name,
            description: nil,
            source: .importedGPX(originalFileName: "straight.gpx"),
            importedAt: TestDates.rideStart,
            originalCreatedAt: TestDates.rideStart
        )

        return Route(
            id: id,
            metadata: metadata,
            points: points,
            bounds: bounds,
            totalDistanceMeters: distanceMeters,
            totalAscentMeters: 20.0,
            totalDescentMeters: 0.0,
            minimumElevationMeters: 600.0,
            maximumElevationMeters: 620.0
        )
    }

    /// Creates an L-shaped turning route.
    static func turnRoute(
        id: Route.ID = TestIDs.routeBeta,
        name: String = "Turn Route"
    ) -> Route {
        let p1 = RoutePoint(coordinate: Coordinate(latitude: 24.7136, longitude: 46.6753), elevationMeters: 600, cumulativeDistanceMeters: 0)
        let p2 = RoutePoint(coordinate: Coordinate(latitude: 24.7200, longitude: 46.6753), elevationMeters: 605, cumulativeDistanceMeters: 700)
        let p3 = RoutePoint(coordinate: Coordinate(latitude: 24.7200, longitude: 46.6850), elevationMeters: 610, cumulativeDistanceMeters: 1600)

        let metadata = RouteMetadata(
            name: name,
            description: nil,
            source: .importedGPX(originalFileName: "turn.gpx"),
            importedAt: TestDates.rideStart,
            originalCreatedAt: TestDates.rideStart
        )

        let bounds = RouteBounds(minimumLatitude: 24.7136, maximumLatitude: 24.7200, minimumLongitude: 46.6753, maximumLongitude: 46.6850)

        return Route(
            id: id,
            metadata: metadata,
            points: [p1, p2, p3],
            bounds: bounds,
            totalDistanceMeters: 1600.0,
            totalAscentMeters: 10.0,
            totalDescentMeters: 0.0
        )
    }

    /// Single climb route.
    static func climbingRoute(
        id: Route.ID = TestIDs.routeGamma,
        name: String = "Climb Route",
        distanceMeters: Double = 3000.0
    ) -> Route {
        var points: [RoutePoint] = []
        let count = 30
        for i in 0..<count {
            let frac = Double(i) / Double(count - 1)
            let lat = 24.7136 + frac * 0.02
            let lon = 46.6753 + frac * 0.01
            let elev = 600.0 + frac * 250.0 // 250m climb
            points.append(RoutePoint(
                coordinate: Coordinate(latitude: lat, longitude: lon),
                elevationMeters: elev,
                cumulativeDistanceMeters: frac * distanceMeters
            ))
        }

        let metadata = RouteMetadata(
            name: name,
            description: nil,
            source: .importedGPX(originalFileName: "climb.gpx"),
            importedAt: TestDates.rideStart,
            originalCreatedAt: TestDates.rideStart
        )

        let bounds = RouteBounds(minimumLatitude: 24.7136, maximumLatitude: 24.7336, minimumLongitude: 46.6753, maximumLongitude: 46.6853)

        return Route(
            id: id,
            metadata: metadata,
            points: points,
            bounds: bounds,
            totalDistanceMeters: distanceMeters,
            totalAscentMeters: 250.0,
            totalDescentMeters: 0.0
        )
    }
}
