import Foundation
@testable import UltraNav

final class FakeRouteImporter: RouteImporting, @unchecked Sendable {
    var resultToReturn: RouteImportResult?
    var errorToThrow: Error?
    private(set) var importCallCount = 0

    init(resultToReturn: RouteImportResult? = nil, errorToThrow: Error? = nil) {
        self.resultToReturn = resultToReturn
        self.errorToThrow = errorToThrow
    }

    func importRoute(from source: RouteImportSource, policy: RouteImportPolicy) async throws -> RouteImportResult {
        importCallCount += 1
        if let error = errorToThrow {
            throw error
        }
        if let result = resultToReturn {
            return result
        }
        let route = Route(
            id: RouteID(sha256Hex: "fakeimport"),
            metadata: RouteMetadata(name: "Imported Fake Route"),
            points: [
                RoutePoint(coordinate: Coordinate(latitude: 37.33, longitude: -122.0), cumulativeDistanceMeters: 0),
                RoutePoint(coordinate: Coordinate(latitude: 37.34, longitude: -122.01), cumulativeDistanceMeters: 1200)
            ],
            totalDistanceMeters: 1200
        )
        return RouteImportResult(route: route, warnings: [])
    }
}
