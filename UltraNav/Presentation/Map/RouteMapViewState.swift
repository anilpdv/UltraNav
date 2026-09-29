import Foundation

public struct MapRoutePoint: Equatable, Sendable {
    public let coordinate: Coordinate
    public let distanceAlongRouteMeters: Double
    public let elevationMeters: Double?

    public init(coordinate: Coordinate, distanceAlongRouteMeters: Double, elevationMeters: Double? = nil) {
        self.coordinate = coordinate
        self.distanceAlongRouteMeters = distanceAlongRouteMeters
        self.elevationMeters = elevationMeters
    }
}

public struct MapMarkerState: Identifiable, Equatable, Sendable {
    public enum MarkerType: String, Codable, Equatable, Sendable {
        case currentPosition
        case start
        case finish
        case cue
    }

    public let id: String
    public let coordinate: Coordinate
    public let type: MarkerType
    public let title: String?

    public init(id: String, coordinate: Coordinate, type: MarkerType, title: String? = nil) {
        self.id = id
        self.coordinate = coordinate
        self.type = type
        self.title = title
    }
}

public struct MapViewportState: Equatable, Sendable {
    public let center: Coordinate
    public let spanMeters: Double

    public init(center: Coordinate, spanMeters: Double = 500.0) {
        self.center = center
        self.spanMeters = spanMeters
    }

    public static let `default` = MapViewportState(center: Coordinate(latitude: 37.7749, longitude: -122.4194))
}

public struct MapOrientationState: Equatable, Sendable {
    public enum Mode: String, Codable, Equatable, Sendable {
        case northUp
        case trackUp
    }

    public let headingDegrees: Double
    public let mode: Mode

    public init(headingDegrees: Double = 0.0, mode: Mode = .trackUp) {
        self.headingDegrees = headingDegrees
        self.mode = mode
    }

    public static let `default` = MapOrientationState()
}

public struct RouteMapViewState: Equatable, Sendable {
    public let routePolyline: [MapRoutePoint]
    public let traveledPolyline: [MapRoutePoint]
    public let currentPosition: MapMarkerState?
    public let startMarker: MapMarkerState?
    public let finishMarker: MapMarkerState?
    public let cueMarkers: [MapMarkerState]
    public let viewport: MapViewportState
    public let orientation: MapOrientationState

    public init(
        routePolyline: [MapRoutePoint] = [],
        traveledPolyline: [MapRoutePoint] = [],
        currentPosition: MapMarkerState? = nil,
        startMarker: MapMarkerState? = nil,
        finishMarker: MapMarkerState? = nil,
        cueMarkers: [MapMarkerState] = [],
        viewport: MapViewportState = .default,
        orientation: MapOrientationState = .default
    ) {
        self.routePolyline = routePolyline
        self.traveledPolyline = traveledPolyline
        self.currentPosition = currentPosition
        self.startMarker = startMarker
        self.finishMarker = finishMarker
        self.cueMarkers = cueMarkers
        self.viewport = viewport
        self.orientation = orientation
    }

    public static let empty = RouteMapViewState()
}
