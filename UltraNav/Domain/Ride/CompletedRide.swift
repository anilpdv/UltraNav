import Foundation

struct CompletedRide: Identifiable,
                      Equatable,
                      Sendable {
    typealias ID = UUID

    let id: ID

    let startedAt: Date
    let endedAt: Date

    let elapsedTimeSeconds: TimeInterval
    let movingTimeSeconds: TimeInterval

    let distanceMeters: Double

    let averageSpeedMetersPerSecond: Double?
    let averageHeartRateBeatsPerMinute: Double?
    let averageCadenceRevolutionsPerMinute: Double?
    let averagePowerWatts: Double?

    let routeID: Route.ID?
}
