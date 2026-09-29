import Foundation
import Observation

@Observable
@MainActor
public final class NavigationViewModel {
    public private(set) var state: NavigationViewState
    private let navigationEngine: any NavigationEngineProviding
    private let routeNavigationCoordinator: RouteNavigationCoordinator
    private let mapper: NavigationViewStateMapper
    private var preferences: UnitPreferences

    private var snapshotTask: Task<Void, Never>?

    init(
        navigationEngine: any NavigationEngineProviding,
        routeNavigationCoordinator: RouteNavigationCoordinator,
        mapper: NavigationViewStateMapper = NavigationViewStateMapper(),
        preferences: UnitPreferences = .default
    ) {
        self.navigationEngine = navigationEngine
        self.routeNavigationCoordinator = routeNavigationCoordinator
        self.mapper = mapper
        self.preferences = preferences
        self.state = mapper.map(
            snapshot: navigationEngine.currentSnapshot,
            preferences: preferences
        )

        startSnapshotConsumer()
    }

    public func handle(_ action: NavigationPresentationAction) {
        Task {
            switch action {
            case .appeared:
                updateState()
            case .startSelected:
                await navigationEngine.send(.start)
            case .stopSelected:
                await navigationEngine.send(.stop)
            case .clearSelected:
                await routeNavigationCoordinator.clearRoute()
            }
        }
    }

    public func updatePreferences(_ newPreferences: UnitPreferences) {
        self.preferences = newPreferences
        updateState()
    }

    private func startSnapshotConsumer() {
        let snapshots = navigationEngine.snapshots
        snapshotTask = Task { [weak self] in
            for await snapshot in snapshots {
                guard let self, !Task.isCancelled else { break }
                self.state = self.mapper.map(
                    snapshot: snapshot,
                    preferences: self.preferences
                )
            }
        }
    }

    private func updateState() {
        state = mapper.map(
            snapshot: navigationEngine.currentSnapshot,
            preferences: preferences
        )
    }
}
