import Foundation

/// Policy rules defining how ride state transitions interact with navigation lifecycle.
struct RideNavigationPolicy: Sendable, Equatable {
    /// Whether starting or resuming a ride should automatically start navigation if a route is ready.
    let startNavigationWithRide: Bool
    
    /// Whether navigation should continue tracking when a ride is paused.
    let continueNavigationWhileRidePaused: Bool
    
    /// Whether navigation should automatically stop when a ride finishes.
    let stopNavigationWhenRideFinishes: Bool

    init(
        startNavigationWithRide: Bool = false,
        continueNavigationWhileRidePaused: Bool = true,
        stopNavigationWhenRideFinishes: Bool = true
    ) {
        self.startNavigationWithRide = startNavigationWithRide
        self.continueNavigationWhileRidePaused = continueNavigationWhileRidePaused
        self.stopNavigationWhenRideFinishes = stopNavigationWhenRideFinishes
    }

    static let `default` = RideNavigationPolicy()
}
