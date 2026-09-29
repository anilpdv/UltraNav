import Foundation

enum ObservedSubsystem: String, CaseIterable, Equatable, Hashable, Sendable {
    case app
    case ride
    case location
    case workout
    case sensors
    case routeLibrary
    case navigation
    case metrics
    case climb
    case presentation
}

struct StateTransitionTrace: Equatable, Sendable {
    let subsystem: ObservedSubsystem
    let fromState: String
    let event: String
    let toState: String
    let changedState: Bool

    init(
        subsystem: ObservedSubsystem,
        fromState: String,
        event: String,
        toState: String,
        changedState: Bool = true
    ) {
        self.subsystem = subsystem
        self.fromState = fromState
        self.event = event
        self.toState = toState
        self.changedState = changedState
    }
}
