import Foundation
@testable import UltraNav

enum NavigationRouteFactory {
    static func createRoute(
        id: UUID = UUID(),
        name: String = "Test Route",
        points: [RoutePoint] = [],
        totalDistanceMeters: Double = 1000.0
    ) -> Route {
        let actualPoints: [RoutePoint]
        if points.isEmpty {
            actualPoints = [
                RoutePoint(coordinate: Coordinate(latitude: 37.7749, longitude: -122.4194), elevationMeters: 10, timestamp: nil, cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.7759, longitude: -122.4194), elevationMeters: 12, timestamp: nil, cumulativeDistanceMeters: 500),
                RoutePoint(coordinate: Coordinate(latitude: 37.7769, longitude: -122.4194), elevationMeters: 15, timestamp: nil, cumulativeDistanceMeters: totalDistanceMeters)
            ]
        } else {
            actualPoints = points
        }

        return Route(
            id: id,
            metadata: RouteMetadata(name: name, sourceFileName: "test.gpx", createdAt: Date()),
            points: actualPoints,
            totalDistanceMeters: totalDistanceMeters
        )
    }

    static func createLinearRoute(pointCount: Int = 10, stepDistanceMeters: Double = 100.0) -> Route {
        var points: [RoutePoint] = []
        for i in 0..<pointCount {
            let dist = Double(i) * stepDistanceMeters
            let lat = 37.7749 + (Double(i) * 0.001)
            points.append(
                RoutePoint(
                    coordinate: Coordinate(latitude: lat, longitude: -122.4194),
                    elevationMeters: Double(i * 2),
                    timestamp: nil,
                    cumulativeDistanceMeters: dist
                )
            )
        }
        let total = Double(pointCount - 1) * stepDistanceMeters
        return createRoute(points: points, totalDistanceMeters: total)
    }

    static func createCue(
        maneuver: NavigationManeuver = .right,
        distanceMeters: Double = 500.0,
        instruction: String = "Turn right onto Pine St"
    ) -> NavigationCue {
        NavigationCue(
            maneuver: maneuver,
            coordinate: Coordinate(latitude: 37.7759, longitude: -122.4194),
            routeDistanceMeters: distanceMeters,
            instruction: instruction
        )
    }
}
