import Foundation

/// Pure parsed value model representing the raw contents of a GPX file.
public struct GPXParsedDocument: Equatable, Hashable, Sendable {
    public let metadata: GPXSourceMetadata
    public let tracks: [GPXParsedTrack]
    public let routes: [GPXParsedRoute]
    public let waypoints: [GPXParsedWaypoint]

    public init(
        metadata: GPXSourceMetadata = GPXSourceMetadata(),
        tracks: [GPXParsedTrack] = [],
        routes: [GPXParsedRoute] = [],
        waypoints: [GPXParsedWaypoint] = []
    ) {
        self.metadata = metadata
        self.tracks = tracks
        self.routes = routes
        self.waypoints = waypoints
    }

    /// Total count of all track points and route points in the document.
    public var totalPointCount: Int {
        let trackPoints = tracks.reduce(0) { sum, trk in
            sum + trk.segments.reduce(0) { segSum, seg in segSum + seg.points.count }
        }
        let routePoints = routes.reduce(0) { sum, rte in
            sum + rte.points.count
        }
        return trackPoints + routePoints
    }
}
