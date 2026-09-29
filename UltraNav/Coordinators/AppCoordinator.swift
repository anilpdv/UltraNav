import Foundation

@MainActor
final class AppCoordinator {
    let rideData: RideDataCoordinator
    let rideLifecycle: RideLifecycleCoordinator
    let routeNavigation: RouteNavigationCoordinator
    let notifications: NavigationNotificationCoordinator

    init(
        rideData: RideDataCoordinator,
        rideLifecycle: RideLifecycleCoordinator,
        routeNavigation: RouteNavigationCoordinator,
        notifications: NavigationNotificationCoordinator
    ) {
        self.rideData = rideData
        self.rideLifecycle = rideLifecycle
        self.routeNavigation = routeNavigation
        self.notifications = notifications
    }

    func activate() {
        rideData.activate()
        routeNavigation.activate()
        notifications.activate()
    }

    func shutdown() {
        notifications.shutdown()
        routeNavigation.shutdown()
        rideData.shutdown()
    }
}
