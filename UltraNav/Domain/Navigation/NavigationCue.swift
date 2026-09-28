import Foundation

enum NavigationManeuver: String, Equatable, Sendable {
    case continueStraight
    case slightLeft
    case left
    case sharpLeft
    case slightRight
    case right
    case sharpRight
    case uTurn
    case arrive
    case unknown
}

struct NavigationCue: Identifiable, Equatable, Sendable {
    typealias ID = UUID

    let id: ID
    let maneuver: NavigationManeuver
    let coordinate: Coordinate

    /// Distance from the route start where the maneuver occurs.
    let routeDistanceMeters: Double

    let instruction: String?

    init(
        id: ID = UUID(),
        maneuver: NavigationManeuver,
        coordinate: Coordinate,
        routeDistanceMeters: Double,
        instruction: String? = nil
    ) {
        self.id = id
        self.maneuver = maneuver
        self.coordinate = coordinate
        self.routeDistanceMeters = routeDistanceMeters
        self.instruction = instruction
    }
}
