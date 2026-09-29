import Foundation

public struct RouteMapViewStateMapper: Sendable {
    public init() {}

    func map(
        navigationSnapshot: NavigationSnapshot,
        route: Route? = nil
    ) -> RouteMapViewState {
        let currentPos = navigationSnapshot.currentLocation.map { coord in
            MapMarkerState(
                id: "current-position",
                coordinate: coord,
                type: .currentPosition,
                title: "Current Location"
            )
        }

        var routePoints: [MapRoutePoint] = []
        if let route = route {
            routePoints = route.points.map { pt in
                MapRoutePoint(
                    coordinate: pt.coordinate,
                    distanceAlongRouteMeters: pt.cumulativeDistanceMeters,
                    elevationMeters: pt.elevationMeters
                )
            }
        }

        var traveledPoints: [MapRoutePoint] = []
        let currentDistance = navigationSnapshot.distanceAlongRouteMeters
        if currentDistance > 0 {
            traveledPoints = routePoints.filter { $0.distanceAlongRouteMeters <= currentDistance }
        }

        let startMarker = routePoints.first.map { pt in
            MapMarkerState(id: "start", coordinate: pt.coordinate, type: .start, title: "Start")
        }
        let finishMarker = routePoints.last.map { pt in
            MapMarkerState(id: "finish", coordinate: pt.coordinate, type: .finish, title: "Finish")
        }

        let heading: Double = 0.0
        let center = navigationSnapshot.currentLocation ?? routePoints.first?.coordinate ?? Coordinate(latitude: 37.7749, longitude: -122.4194)

        return RouteMapViewState(
            routePolyline: routePoints,
            traveledPolyline: traveledPoints,
            currentPosition: currentPos,
            startMarker: startMarker,
            finishMarker: finishMarker,
            cueMarkers: [],
            viewport: MapViewportState(center: center, spanMeters: 500),
            orientation: MapOrientationState(headingDegrees: heading, mode: .trackUp)
        )
    }
}
