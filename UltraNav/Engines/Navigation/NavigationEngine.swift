import Foundation
import OSLog

@MainActor
final class NavigationEngine: NavigationEngineProviding {
    private(set) var currentSnapshot: NavigationSnapshot
    private let snapshotChannel = AsyncEventChannel<NavigationSnapshot>(bufferingPolicy: .bufferingNewest(5))
    var snapshots: AsyncStream<NavigationSnapshot> {
        snapshotChannel.makeStream()
    }

    private let notificationChannel = AsyncEventChannel<NavigationNotification>(bufferingPolicy: .bufferingNewest(20))
    var notifications: AsyncStream<NavigationNotification> {
        notificationChannel.makeStream()
    }

    private let routeStore: (any RouteStoring)?
    private let routeValidator: any NavigationRouteValidating
    private let routeMatcher: any RouteMatching
    private let cueProvider: any NavigationCueProviding
    private let cueProgressor: any CueProgressing
    private let offRouteEvaluator: any OffRouteEvaluating
    private let completionEvaluator: any RouteCompletionEvaluating
    private let snapshotBuilder: NavigationSnapshotBuilder
    private let failureMapper: NavigationEngineFailureMapper

    private(set) var stateMachine: NavigationStateMachine
    private(set) var routeState: NavigationRouteState
    private(set) var progressState: NavigationProgressState

    private(set) var latestLocation: LocationSample?
    private(set) var cueProgress: CueProgress?
    private(set) var offRouteStatus: OffRouteStatus
    private(set) var activeFailure: NavigationFailure?

    private var commandInProgress: NavigationEngineCommand?

    init(
        routeStore: (any RouteStoring)? = nil,
        routeValidator: any NavigationRouteValidating = NavigationRouteValidator(),
        routeMatcher: any RouteMatching = RouteMatcher(),
        cueProvider: any NavigationCueProviding = NavigationCueBuilder(),
        cueProgressor: any CueProgressing = CueProgressor(),
        offRouteEvaluator: any OffRouteEvaluating = LegacyOffRouteEvaluator(),
        completionEvaluator: any RouteCompletionEvaluating = LegacyRouteCompletionEvaluator(),
        snapshotBuilder: NavigationSnapshotBuilder = NavigationSnapshotBuilder(),
        failureMapper: NavigationEngineFailureMapper = NavigationEngineFailureMapper()
    ) {
        self.routeStore = routeStore
        self.routeValidator = routeValidator
        self.routeMatcher = routeMatcher
        self.cueProvider = cueProvider
        self.cueProgressor = cueProgressor
        self.offRouteEvaluator = offRouteEvaluator
        self.completionEvaluator = completionEvaluator
        self.snapshotBuilder = snapshotBuilder
        self.failureMapper = failureMapper

        self.stateMachine = NavigationStateMachine()
        self.routeState = NavigationRouteState()
        self.progressState = NavigationProgressState()

        self.latestLocation = nil
        self.cueProgress = nil
        self.offRouteStatus = .unknown
        self.activeFailure = nil

        self.currentSnapshot = .inactive
    }

    // MARK: - Command Dispatch

    func send(_ command: NavigationEngineCommand) async {
        guard commandInProgress == nil else {
            return
        }

        commandInProgress = command
        defer {
            commandInProgress = nil
        }

        switch command {
        case .loadRoute(let id):
            await loadRoute(id: id)

        case .useRoute(let route):
            await useRoute(route)

        case .start:
            await startNavigation()

        case .stop:
            await stopNavigation()

        case .clearRoute:
            await clearRoute()

        case .recover:
            await recover()

        case .reset:
            await reset()
        }
    }

    // MARK: - Route Loading

    private func loadRoute(id: Route.ID) async {
        guard let routeStore else {
            await handleRouteLoadFailure(NavigationFailure.routeUnavailable)
            return
        }

        do {
            let transition = try stateMachine.handle(.routeLoadRequested)
            apply(transition)

            do {
                let route = try await routeStore.loadRoute(id: id)
                try await installRoute(route)
            } catch {
                await handleRouteLoadFailure(error)
            }
        } catch {
            await handleRouteLoadFailure(NavigationFailure.routeUnavailable)
        }
    }

    private func useRoute(_ route: Route) async {
        do {
            if stateMachine.state != .inactive {
                await reset()
            }

            let transition = try stateMachine.handle(.routeLoadRequested)
            apply(transition)

            try await installRoute(route)
        } catch {
            await handleRouteLoadFailure(error)
        }
    }

    private func installRoute(_ route: Route) async throws {
        do {
            try routeValidator.validate(route)
        } catch {
            throw NavigationFailure.invalidRoute
        }

        let cues: [NavigationCue]
        do {
            cues = try cueProvider.cues(for: route)
        } catch {
            cues = []
        }

        routeState.load(route: route, cues: cues)
        progressState.reset()
        latestLocation = nil
        cueProgress = nil
        offRouteStatus = .unknown
        activeFailure = nil

        let transition = try stateMachine.handle(.routeLoadSucceeded)
        apply(transition)
    }

    private func handleRouteLoadFailure(_ error: Error) async {
        let failure = failureMapper.map(error)
        activeFailure = failure
        routeState.clear()
        progressState.reset()

        let transition = try? stateMachine.handle(.routeLoadFailed(failure))
        if let transition {
            apply(transition)
        } else {
            publishSnapshot()
        }
    }

    // MARK: - Navigation Lifecycle

    private func startNavigation() async {
        guard routeState.route != nil else {
            activeFailure = .routeUnavailable
            publishSnapshot()
            return
        }

        do {
            let startRequested = try stateMachine.handle(.navigationStartRequested)
            apply(startRequested)

            progressState.reset()
            cueProgress = nil
            offRouteStatus = .unknown
            activeFailure = nil

            let startSucceeded = try stateMachine.handle(.navigationStartSucceeded)
            apply(startSucceeded)
        } catch {
            activeFailure = .unexpected
            publishSnapshot()
        }
    }

    private func stopNavigation() async {
        do {
            let transition = try stateMachine.handle(.navigationStopRequested)
            apply(transition)
        } catch {
            // If already inactive or ready, ignore
            return
        }
    }

    private func clearRoute() async {
        guard stateMachine.state == .ready ||
              stateMachine.state == .finished ||
              stateMachine.state == .failed(failure: .invalidRoute, recovery: .returnToInactive) ||
              stateMachine.state.name == .failed ||
              stateMachine.state == .inactive else {
            return
        }

        routeState.clear()
        progressState.reset()
        latestLocation = nil
        cueProgress = nil
        offRouteStatus = .unknown
        activeFailure = nil

        let transition = try? stateMachine.handle(.routeClearRequested)
        if let transition {
            apply(transition)
        } else {
            stateMachine = NavigationStateMachine(initialState: .inactive)
            publishSnapshot()
        }
    }

    private func recover() async {
        do {
            let transition = try stateMachine.handle(.recoveryRequested)
            activeFailure = nil
            apply(transition)
        } catch {
            return
        }
    }

    private func reset() async {
        routeState.clear()
        progressState.reset()
        latestLocation = nil
        cueProgress = nil
        offRouteStatus = .unknown
        activeFailure = nil

        stateMachine = NavigationStateMachine(initialState: .inactive)
        publishSnapshot()
    }

    // MARK: - Location Processing

    func consume(location: LocationSample) {
        latestLocation = location

        switch stateMachine.state {
        case .navigating,
             .suspectedOffRoute,
             .offRoute,
             .rejoining:
            processNavigationLocation(location)

        case .inactive,
             .loading,
             .ready,
             .starting,
             .finishing,
             .finished,
             .failed:
            publishSnapshot()
        }
    }

    private func processNavigationLocation(_ location: LocationSample) {
        guard let route = routeState.route else {
            failNavigation(.routeUnavailable)
            return
        }

        do {
            guard let match = try routeMatcher.match(
                location: location,
                route: route,
                previousMatch: progressState.latestMatch
            ) else {
                publishSnapshot()
                return
            }

            progressState.update(match: match, locationTimestamp: location.timestamp)

            let previousCueProgress = cueProgress
            let newCueProgress = cueProgressor.progress(
                cues: routeState.cues,
                routeMatch: match,
                previous: previousCueProgress
            )
            self.cueProgress = newCueProgress

            // Emit cue notifications on progression
            if let pending = newCueProgress.pendingNotification {
                notificationChannel.send(pending)
            } else if let nextCue = newCueProgress.nextCue, previousCueProgress?.nextCue?.id != nextCue.id {
                notificationChannel.send(.approachingCue(nextCue))
            }

            let evaluation = offRouteEvaluator.evaluate(
                match: match,
                previousStatus: offRouteStatus,
                timestamp: location.timestamp
            )

            applyOffRouteEvaluation(evaluation)

            if completionEvaluator.isRouteCompleted(route: route, match: match, location: location) {
                completeNavigation()
            } else {
                publishSnapshot()
            }
        } catch {
            failNavigation(.calculationFailed)
        }
    }

    private func applyOffRouteEvaluation(_ evaluation: OffRouteEvaluation) {
        let previous = offRouteStatus
        offRouteStatus = evaluation.status

        do {
            switch (stateMachine.state, evaluation.status) {
            case (.navigating, .suspected):
                let transition = try stateMachine.handle(.possibleDeviationDetected)
                apply(transition)
                notificationChannel.send(.possibleDeviation)

            case (.navigating, .offRoute):
                _ = try stateMachine.handle(.possibleDeviationDetected)
                let transition = try stateMachine.handle(.deviationConfirmed)
                apply(transition)
                notificationChannel.send(.offRoute)

            case (.suspectedOffRoute, .offRoute):
                let transition = try stateMachine.handle(.deviationConfirmed)
                apply(transition)
                notificationChannel.send(.offRoute)

            case (.suspectedOffRoute, .onRoute):
                let transition = try stateMachine.handle(.rejoinConfirmed)
                apply(transition)

            case (.offRoute, .rejoining):
                let transition = try stateMachine.handle(.rejoinDetected)
                apply(transition)

            case (.offRoute, .onRoute):
                _ = try stateMachine.handle(.rejoinDetected)
                let transition = try stateMachine.handle(.rejoinConfirmed)
                apply(transition)
                notificationChannel.send(.routeRejoined)

            case (.rejoining, .onRoute):
                let transition = try stateMachine.handle(.rejoinConfirmed)
                apply(transition)
                notificationChannel.send(.routeRejoined)

            default:
                break
            }
        } catch {
            offRouteStatus = previous
        }
    }

    private func completeNavigation() {
        do {
            let finishingTransition = try stateMachine.handle(.routeCompleted)
            apply(finishingTransition)

            let finishedTransition = try stateMachine.handle(.finishSucceeded)
            offRouteStatus = .onRoute
            apply(finishedTransition)

            notificationChannel.send(.routeCompleted)
        } catch {
            failNavigation(.calculationFailed)
        }
    }

    private func failNavigation(_ failure: NavigationFailure) {
        activeFailure = failure
        publishSnapshot()
    }

    // MARK: - State Machine Effect Application

    private func apply(_ transition: NavigationTransition) {
        publishSnapshot()
    }

    // MARK: - Snapshot Publication

    func publishSnapshot() {
        let snapshot = snapshotBuilder.makeSnapshot(
            state: stateMachine.state,
            route: routeState.route,
            location: latestLocation,
            match: progressState.latestMatch,
            cueProgress: cueProgress,
            offRouteStatus: offRouteStatus,
            failure: activeFailure
        )

        guard snapshot != currentSnapshot else { return }
        currentSnapshot = snapshot
        snapshotChannel.send(snapshot)
    }
}
