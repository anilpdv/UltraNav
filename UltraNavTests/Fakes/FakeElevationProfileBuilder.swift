import Foundation
@testable import UltraNav

final class FakeElevationProfileBuilder: ElevationProfileBuilding, @unchecked Sendable {
    var stubbedResult: Result<ElevationProfile, ClimbFailure>?
    var buildCallCount = 0
    var lastRoute: Route?

    func buildProfile(for route: Route) throws -> ElevationProfile {
        buildCallCount += 1
        lastRoute = route
        if let stubbed = stubbedResult {
            switch stubbed {
            case .success(let profile): return profile
            case .failure(let error): throw error
            }
        }
        return ElevationProfile(
            routeID: route.id,
            points: [
                ElevationProfilePoint(distanceMeters: 0, elevationMeters: 100, originalIndex: 0),
                ElevationProfilePoint(distanceMeters: 1000, elevationMeters: 200, originalIndex: 1)
            ],
            totalAscentMeters: 100,
            totalDescentMeters: 0,
            minElevationMeters: 100,
            maxElevationMeters: 200
        )
    }
}
