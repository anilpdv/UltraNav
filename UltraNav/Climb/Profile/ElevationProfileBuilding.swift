import Foundation

/// Protocol for building an ElevationProfile from a domain Route.
protocol ElevationProfileBuilding: Sendable {
    func buildProfile(for route: Route) throws -> ElevationProfile
}
