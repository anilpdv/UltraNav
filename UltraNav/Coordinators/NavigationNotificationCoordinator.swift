import Foundation

@MainActor
final class NavigationNotificationCoordinator {
    private let navigationEngine: any NavigationEngineProviding
    private let climbEngine: any ClimbEngineProviding
    private let haptics: any HapticProviding

    private var navigationNotificationTask: Task<Void, Never>?
    private var climbNotificationTask: Task<Void, Never>?

    private(set) var isActive: Bool = false

    init(
        navigationEngine: any NavigationEngineProviding,
        climbEngine: any ClimbEngineProviding,
        haptics: any HapticProviding
    ) {
        self.navigationEngine = navigationEngine
        self.climbEngine = climbEngine
        self.haptics = haptics
    }

    func activate() {
        guard !isActive else { return }
        isActive = true

        startNavigationNotificationConsumer()
        startClimbNotificationConsumer()
    }

    func shutdown() {
        navigationNotificationTask?.cancel()
        climbNotificationTask?.cancel()

        navigationNotificationTask = nil
        climbNotificationTask = nil

        isActive = false
    }

    // MARK: - Consumers

    private func startNavigationNotificationConsumer() {
        let stream = navigationEngine.notifications
        navigationNotificationTask = Task { [weak self] in
            for await notification in stream {
                guard let self, !Task.isCancelled else { break }
                await self.handle(navigationNotification: notification)
            }
        }
    }

    private func startClimbNotificationConsumer() {
        let stream = climbEngine.notifications
        climbNotificationTask = Task { [weak self] in
            for await notification in stream {
                guard let self, !Task.isCancelled else { break }
                await self.handle(climbNotification: notification)
            }
        }
    }

    // MARK: - Notification Mapping

    func handle(navigationNotification: NavigationNotification) async {
        switch navigationNotification {
        case .approachingCue:
            await haptics.play(.turnApproaching)
        case .immediateCue:
            await haptics.play(.turnImmediate)
        case .possibleDeviation:
            await haptics.play(.possibleDeviation)
        case .offRoute:
            await haptics.play(.offRoute)
        case .routeRejoined:
            await haptics.play(.routeRejoined)
        case .routeCompleted:
            await haptics.play(.rideFinished)
        }
    }

    func handle(climbNotification: ClimbNotification) async {
        switch climbNotification {
        case .climbApproaching:
            await haptics.play(.climbApproaching)
        case .climbStarted:
            await haptics.play(.climbStarted)
        case .climbCompleted:
            await haptics.play(.climbCompleted)
        case .routeAnalyzed, .climbSkipped, .allClimbsCompleted, .analysisFailed:
            break
        }
    }
}
