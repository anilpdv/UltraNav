import Foundation
@testable import UltraNav

struct ElevationProfileFactory {
    static func makeRoute(
        id: UUID = UUID(),
        pointCount: Int = 20,
        distanceStep: Double = 100,
        elevationStep: Double = 5
    ) -> Route {
        var points: [RoutePoint] = []
        for i in 0..<pointCount {
            let dist = Double(i) * distanceStep
            let ele = 100.0 + Double(i) * elevationStep
            points.append(RoutePoint(
                coordinate: Coordinate(latitude: 37.0 + Double(i) * 0.001, longitude: -122.0 + Double(i) * 0.001),
                elevationMeters: ele,
                timestamp: Date(),
                cumulativeDistanceMeters: dist
            ))
        }

        return Route(
            id: id,
            metadata: RouteMetadata(name: "Test Route", sourceFileName: nil, createdAt: Date()),
            points: points,
            totalDistanceMeters: Double(max(0, pointCount - 1)) * distanceStep
        )
    }

    static func makeProfile(
        routeID: UUID = UUID(),
        pointCount: Int = 10,
        distanceStep: Double = 200,
        elevationStep: Double = 10
    ) -> ElevationProfile {
        var points: [ElevationProfilePoint] = []
        for i in 0..<pointCount {
            points.append(ElevationProfilePoint(
                distanceMeters: Double(i) * distanceStep,
                elevationMeters: 100.0 + Double(i) * elevationStep,
                originalIndex: i
            ))
        }

        return ElevationProfile(
            routeID: routeID,
            points: points,
            totalAscentMeters: Double(max(0, pointCount - 1)) * elevationStep,
            totalDescentMeters: 0,
            minElevationMeters: 100.0,
            maxElevationMeters: 100.0 + Double(max(0, pointCount - 1)) * elevationStep
        )
    }

    static func makeNavSnapshot(
        distanceAlongRoute: Double = 0,
        distanceRemaining: Double = 0,
        offRouteStatus: OffRouteStatus = .onRoute
    ) -> NavigationSnapshot {
        NavigationSnapshot(
            state: .navigating,
            routeProgress: 0,
            distanceAlongRouteMeters: distanceAlongRoute,
            distanceRemainingMeters: distanceRemaining,
            offRouteStatus: offRouteStatus
        )
    }
}
