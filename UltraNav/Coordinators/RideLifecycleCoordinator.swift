import Foundation

@MainActor
protocol RideLifecycleCoordinating: AnyObject, Sendable {
    func prepare() async
    func start() async
    func pause() async
    func resume() async
    func finish() async
    func reset() async
}

@MainActor
final class RideLifecycleCoordinator: RideLifecycleCoordinating {
    private let rideEngine: any RideEngineProviding
    private let metricsEngine: any MetricsEngineProviding
    private let navigationEngine: any NavigationEngineProviding
    private let climbEngine: any ClimbEngineProviding
    private let clock: any ClockProviding
    private let navigationPolicy: RideNavigationPolicy

    private var commandInProgress: RideLifecycleCommand?

    private enum RideLifecycleCommand: Equatable {
        case prepare
        case start
        case pause
        case resume
        case finish
        case reset
    }

    init(
        rideEngine: any RideEngineProviding,
        metricsEngine: any MetricsEngineProviding,
        navigationEngine: any NavigationEngineProviding,
        climbEngine: any ClimbEngineProviding,
        clock: any ClockProviding,
        navigationPolicy: RideNavigationPolicy = .default
    ) {
        self.rideEngine = rideEngine
        self.metricsEngine = metricsEngine
        self.navigationEngine = navigationEngine
        self.climbEngine = climbEngine
        self.clock = clock
        self.navigationPolicy = navigationPolicy
    }

    func prepare() async {
        guard commandInProgress == nil else { return }
        commandInProgress = .prepare
        defer { commandInProgress = nil }

        await rideEngine.send(.prepare)
    }

    func start() async {
        guard commandInProgress == nil else { return }
        commandInProgress = .start
        defer { commandInProgress = nil }

        let date = clock.now

        await rideEngine.send(.start(at: date))

        guard rideEngine.currentSnapshot.state == .active else {
            return
        }

        await metricsEngine.send(.start(at: date))

        if navigationPolicy.startNavigationWithRide,
           navigationEngine.currentSnapshot.state == .ready {
            await navigationEngine.send(.start)
        }
    }

    func pause() async {
        guard commandInProgress == nil else { return }
        commandInProgress = .pause
        defer { commandInProgress = nil }

        let date = clock.now

        await rideEngine.send(.pause(at: date))

        guard rideEngine.currentSnapshot.state == .paused else {
            return
        }

        await metricsEngine.send(.pause(at: date))

        if !navigationPolicy.continueNavigationWhileRidePaused {
            await navigationEngine.send(.stop)
        }
    }

    func resume() async {
        guard commandInProgress == nil else { return }
        commandInProgress = .resume
        defer { commandInProgress = nil }

        let date = clock.now

        await rideEngine.send(.resume(at: date))

        guard rideEngine.currentSnapshot.state == .active else {
            return
        }

        await metricsEngine.send(.resume(at: date))

        if navigationPolicy.startNavigationWithRide,
           navigationEngine.currentSnapshot.state == .ready {
            await navigationEngine.send(.start)
        }
    }

    func finish() async {
        guard commandInProgress == nil else { return }
        commandInProgress = .finish
        defer { commandInProgress = nil }

        let date = clock.now

        await rideEngine.send(.finish(at: date))
        await metricsEngine.send(.finish(at: date))

        if navigationPolicy.stopNavigationWhenRideFinishes {
            await navigationEngine.send(.stop)
        }
    }

    func reset() async {
        guard commandInProgress == nil else { return }
        commandInProgress = .reset
        defer { commandInProgress = nil }

        await rideEngine.send(.reset)
        await metricsEngine.send(.reset)
        await navigationEngine.send(.reset)
        await climbEngine.send(.reset)
    }
}
