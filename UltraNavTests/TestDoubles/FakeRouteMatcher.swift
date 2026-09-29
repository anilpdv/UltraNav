import Foundation
@testable import UltraNav

final class FakeRouteMatcher: RouteMatching, @unchecked Sendable {
    var stubbedMatch: RouteMatch?
    var matchedLocations: [LocationSample] = []
    var matchedRoutes: [Route] = []

    init(stubbedMatch: RouteMatch? = nil) {
        self.stubbedMatch = stubbedMatch
    }

    func match(
        location: LocationSample,
        route: Route,
        previousMatch: RouteMatch?
    ) throws -> RouteMatch? {
        matchedLocations.append(location)
        matchedRoutes.append(route)
        return stubbedMatch
    }
}
