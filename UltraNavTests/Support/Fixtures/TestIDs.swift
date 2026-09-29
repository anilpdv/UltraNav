import Foundation
@testable import UltraNav

/// Standardized fixed domain identifiers for reproducible test suites.
enum TestIDs {
    static let routeAlpha = Route.ID(rawValue: "route-alpha-001")
    static let routeBeta = Route.ID(rawValue: "route-beta-002")
    static let routeGamma = Route.ID(rawValue: "route-gamma-003")

    static let heartRateSensor = SensorIdentifier(rawValue: "sensor-hr-001")
    static let powerSensor = SensorIdentifier(rawValue: "sensor-power-002")
    static let speedCadenceSensor = SensorIdentifier(rawValue: "sensor-csc-003")

    static let workoutSession = "workout-session-001"
}
