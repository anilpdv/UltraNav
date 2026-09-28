import Foundation

struct RideDependencyPolicy: Equatable, Sendable {
    let requiresLocation: Bool
    let requiresWorkout: Bool
    let allowsRideWithoutSensors: Bool

    static let outdoorCycling = RideDependencyPolicy(
        requiresLocation: true,
        requiresWorkout: true,
        allowsRideWithoutSensors: true
    )
}
