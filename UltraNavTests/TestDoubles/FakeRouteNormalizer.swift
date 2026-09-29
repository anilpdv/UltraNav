import Foundation
@testable import UltraNav

final class FakeRouteNormalizer: RouteNormalizing, @unchecked Sendable {
    var resultRoute: Route?
    var warningsToEmit: [RouteNormalizationWarning] = []
    var errorToThrow: Error?
    private(set) var normalizeCallCount = 0

    init(
        resultRoute: Route? = nil,
        warningsToEmit: [RouteNormalizationWarning] = [],
        errorToThrow: Error? = nil
    ) {
        self.resultRoute = resultRoute
        self.warningsToEmit = warningsToEmit
        self.errorToThrow = errorToThrow
    }

    func normalize(
        document: GPXParsedDocument,
        source: RouteSource,
        fallbackName: String,
        policy: RouteNormalizationPolicy
    ) throws -> RouteNormalizationResult {
        normalizeCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        if let route = resultRoute {
            return RouteNormalizationResult(route: route, warnings: warningsToEmit)
        }
        let fallbackRoute = Route(
            id: RouteID(sha256Hex: "dummy"),
            metadata: RouteMetadata(name: fallbackName, source: source),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.0, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.01, longitude: -122.01), cumulativeDistanceMeters: 1000)
            ],
            totalDistanceMeters: 1000
        )
        return RouteNormalizationResult(route: fallbackRoute, warnings: warningsToEmit)
    }
}
