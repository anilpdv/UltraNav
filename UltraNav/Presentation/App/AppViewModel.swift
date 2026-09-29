import Foundation
import Observation

public struct AppViewState: Equatable, Sendable {
    public let isRiding: Bool
    public let alert: AlertViewState?
    public let banner: BannerViewState?

    public init(
        isRiding: Bool = false,
        alert: AlertViewState? = nil,
        banner: BannerViewState? = nil
    ) {
        self.isRiding = isRiding
        self.alert = alert
        self.banner = banner
    }

    public static let initial = AppViewState()
}

@Observable
@MainActor
public final class AppViewModel {
    public let ride: RideViewModel
    public let metrics: MetricsViewModel
    public let navigation: NavigationViewModel
    public let climb: ClimbViewModel
    public let routes: RouteLibraryViewModel
    public let map: RouteMapViewModel

    public private(set) var alert: AlertViewState?
    public private(set) var banner: BannerViewState?

    public init(
        ride: RideViewModel,
        metrics: MetricsViewModel,
        navigation: NavigationViewModel,
        climb: ClimbViewModel,
        routes: RouteLibraryViewModel,
        map: RouteMapViewModel
    ) {
        self.ride = ride
        self.metrics = metrics
        self.navigation = navigation
        self.climb = climb
        self.routes = routes
        self.map = map
    }

    public var isRiding: Bool {
        ride.state.phase == .active || ride.state.phase == .paused || ride.state.phase == .preparing
    }

    public func showAlert(_ alert: AlertViewState) {
        self.alert = alert
    }

    public func dismissAlert() {
        self.alert = nil
    }

    public func showBanner(_ banner: BannerViewState) {
        self.banner = banner
    }

    public func dismissBanner() {
        self.banner = nil
    }
}
