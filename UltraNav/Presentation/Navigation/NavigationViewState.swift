import Foundation

public struct NavigationViewState: Equatable, Sendable {
    public let phase: NavigationPhaseViewState
    public let routeName: String?
    public let progressText: String?
    public let distanceRemaining: MetricDisplayValue?
    public let nextCue: CueViewState?
    public let banner: NavigationBannerState?
    public let map: RouteMapViewState
    public let canStart: Bool
    public let canStop: Bool
    public let canClear: Bool

    public init(
        phase: NavigationPhaseViewState,
        routeName: String? = nil,
        progressText: String? = nil,
        distanceRemaining: MetricDisplayValue? = nil,
        nextCue: CueViewState? = nil,
        banner: NavigationBannerState? = nil,
        map: RouteMapViewState = .empty,
        canStart: Bool = false,
        canStop: Bool = false,
        canClear: Bool = false
    ) {
        self.phase = phase
        self.routeName = routeName
        self.progressText = progressText
        self.distanceRemaining = distanceRemaining
        self.nextCue = nextCue
        self.banner = banner
        self.map = map
        self.canStart = canStart
        self.canStop = canStop
        self.canClear = canClear
    }

    public static let initial = NavigationViewState(
        phase: .inactive,
        map: .empty
    )
}
