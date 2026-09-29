import Foundation
import Observation

@Observable
@MainActor
public final class RouteLibraryViewModel {
    public private(set) var state: RouteLibraryViewState
    private let routeLibraryEngine: any RouteLibraryProviding
    private let routeNavigationCoordinator: RouteNavigationCoordinator
    private let mapper: RouteLibraryViewStateMapper
    private var preferences: UnitPreferences

    private var pendingDeleteRouteID: Route.ID?
    private var snapshotTask: Task<Void, Never>?

    init(
        routeLibraryEngine: any RouteLibraryProviding,
        routeNavigationCoordinator: RouteNavigationCoordinator,
        mapper: RouteLibraryViewStateMapper = RouteLibraryViewStateMapper(),
        preferences: UnitPreferences = .default
    ) {
        self.routeLibraryEngine = routeLibraryEngine
        self.routeNavigationCoordinator = routeNavigationCoordinator
        self.mapper = mapper
        self.preferences = preferences
        self.state = mapper.map(
            snapshot: routeLibraryEngine.currentSnapshot,
            activeRouteID: routeNavigationCoordinator.activeRouteID,
            pendingDeleteRouteID: nil,
            preferences: preferences
        )

        startSnapshotConsumer()
    }

    public func handle(_ action: RouteLibraryPresentationAction) {
        Task {
            switch action {
            case .appeared:
                await routeLibraryEngine.send(.load)
                updateState()
            case .importSelected:
                break
            case .importSourceReceived(let source):
                await routeLibraryEngine.send(.importSource(source))
            case .routeSelected(let id):
                await routeNavigationCoordinator.selectRoute(id: id)
                updateState()
            case .routeDeleteRequested(let id):
                if routeNavigationCoordinator.canDeleteRoute(id: id) {
                    pendingDeleteRouteID = id
                    updateState()
                }
            case .routeDeleteConfirmed(let id):
                pendingDeleteRouteID = nil
                try? await routeNavigationCoordinator.deleteRoute(id: id)
                updateState()
            case .routeDeleteCancelled:
                pendingDeleteRouteID = nil
                updateState()
            case .errorDismissed:
                updateState()
            }
        }
    }

    public func updatePreferences(_ newPreferences: UnitPreferences) {
        self.preferences = newPreferences
        updateState()
    }

    private func startSnapshotConsumer() {
        let snapshots = routeLibraryEngine.snapshots
        snapshotTask = Task { [weak self] in
            for await snapshot in snapshots {
                guard let self, !Task.isCancelled else { break }
                self.state = self.mapper.map(
                    snapshot: snapshot,
                    activeRouteID: self.routeNavigationCoordinator.activeRouteID,
                    pendingDeleteRouteID: self.pendingDeleteRouteID,
                    preferences: self.preferences
                )
            }
        }
    }

    private func updateState() {
        state = mapper.map(
            snapshot: routeLibraryEngine.currentSnapshot,
            activeRouteID: routeNavigationCoordinator.activeRouteID,
            pendingDeleteRouteID: pendingDeleteRouteID,
            preferences: preferences
        )
    }
}
