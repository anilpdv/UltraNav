import Foundation
import Combine

/// Presentation adapter providing ObservableObject projections over NavigationEngine snapshots.
@MainActor
final class LegacyNavigationAdapter: ObservableObject {
    private let navigationEngine: any NavigationEngineProviding
    private var snapshotTask: Task<Void, Never>?

    @Published private(set) var snapshot: NavigationSnapshot

    var isNavigating: Bool {
        snapshot.state == .navigating
    }

    var isOffRoute: Bool {
        snapshot.offRouteStatus == .offRoute || snapshot.offRouteStatus == .suspected
    }

    var progress: Double {
        snapshot.routeProgress
    }

    var distanceRemaining: Double {
        snapshot.distanceRemainingMeters
    }

    var currentCue: NavigationCue? {
        snapshot.nextCue
    }

    var routeID: Route.ID? {
        snapshot.routeID
    }

    var routeName: String? {
        snapshot.routeName
    }

    init(navigationEngine: any NavigationEngineProviding) {
        self.navigationEngine = navigationEngine
        self.snapshot = navigationEngine.currentSnapshot

        self.snapshotTask = Task { [weak self] in
            guard let self else { return }
            for await newSnapshot in self.navigationEngine.snapshots {
                guard !Task.isCancelled else { break }
                self.snapshot = newSnapshot
            }
        }
    }

    deinit {
        snapshotTask?.cancel()
    }

    func load(route: Route) async {
        await navigationEngine.send(.useRoute(route))
        self.snapshot = navigationEngine.currentSnapshot
    }

    func startNavigation() async {
        await navigationEngine.send(.start)
        self.snapshot = navigationEngine.currentSnapshot
    }

    func stopNavigation() async {
        await navigationEngine.send(.stop)
        self.snapshot = navigationEngine.currentSnapshot
    }

    func clearRoute() async {
        await navigationEngine.send(.clearRoute)
        self.snapshot = navigationEngine.currentSnapshot
    }
}
