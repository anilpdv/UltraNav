import Foundation

/// Fast spatial index and edge storage for a canonical Route.
public struct RouteGeometryIndex: Sendable {
    public let routeId: RouteID
    public let totalDistanceMeters: Double
    public let edges: [RouteGeometryEdge]
    public let boundingBox: GeoBoundingBox

    public init(route: Route) {
        self.routeId = route.id
        self.totalDistanceMeters = route.totalDistanceMeters
        self.boundingBox = GeoBoundingBox(coordinates: route.points.map(\.coordinate))

        var calculatedEdges: [RouteGeometryEdge] = []
        guard route.points.count >= 2 else {
            self.edges = []
            return
        }

        for i in 0..<(route.points.count - 1) {
            let p1 = route.points[i]
            let p2 = route.points[i + 1]
            calculatedEdges.append(RouteGeometryEdge(index: i, startPoint: p1, endPoint: p2))
        }
        self.edges = calculatedEdges
    }

    /// Selects candidate edges around a coordinate, taking advantage of previous match locality when available.
    public func candidateEdges(
        near coordinate: Coordinate,
        searchRadiusMeters: Double,
        previousEdgeIndex: Int? = nil,
        forwardWindow: Int = 30,
        backwardWindow: Int = 10
    ) -> [RouteGeometryEdge] {
        guard !edges.isEmpty else { return [] }

        if let prev = previousEdgeIndex, prev >= 0, prev < edges.count {
            let startIdx = max(0, prev - backwardWindow)
            let endIdx = min(edges.count - 1, prev + forwardWindow)
            let localCandidates = Array(edges[startIdx...endIdx])

            let matches = localCandidates.filter { edge in
                edge.boundingBox.contains(coordinate, bufferDegrees: searchRadiusMeters / 111_000.0)
            }

            if !matches.isEmpty {
                return localCandidates
            }
        }

        // Global search fallback using expanded bounding boxes
        let candidates = edges.filter { edge in
            edge.boundingBox.contains(coordinate, bufferDegrees: searchRadiusMeters / 111_000.0)
        }

        return candidates.isEmpty ? edges : candidates
    }
}
