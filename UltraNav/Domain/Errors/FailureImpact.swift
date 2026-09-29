import Foundation

struct FailureImpact: OptionSet, Equatable, Hashable, Sendable {
    let rawValue: Int

    static let blocksAppLaunch = FailureImpact(rawValue: 1 << 0)
    static let blocksRidePreparation = FailureImpact(rawValue: 1 << 1)
    static let blocksRideStart = FailureImpact(rawValue: 1 << 2)
    static let degradesActiveRide = FailureImpact(rawValue: 1 << 3)
    static let blocksNavigation = FailureImpact(rawValue: 1 << 4)
    static let blocksSensors = FailureImpact(rawValue: 1 << 5)
    static let blocksRouteImport = FailureImpact(rawValue: 1 << 6)
    static let threatensRidePersistence = FailureImpact(rawValue: 1 << 7)
    static let requiresUserAttention = FailureImpact(rawValue: 1 << 8)

    static let none: FailureImpact = []
}
