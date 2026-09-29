import Foundation
import Observation

public enum RouteMapPresentationAction: Equatable, Sendable {
    case appeared
    case toggleOrientation
}

@Observable
@MainActor
public final class RouteMapViewModel {
    public private(set) var state: RouteMapViewState
    private let navigationEngine: any NavigationEngineProviding
    private let mapper: RouteMapViewStateMapper
    private var orientationMode: MapOrientationState.Mode = .trackUp

    private var snapshotTask: Task<Void, Never>?

    init(
        navigationEngine: any NavigationEngineProviding,
        mapper: RouteMapViewStateMapper = RouteMapViewStateMapper()
    ) {
        self.navigationEngine = navigationEngine
        self.mapper = mapper
        self.state = mapper.map(navigationSnapshot: navigationEngine.currentSnapshot)

        startSnapshotConsumer()
    }

    public func handle(_ action: RouteMapPresentationAction) {
        switch action {
        case .appeared:
            updateState()
        case .toggleOrientation:
            orientationMode = (orientationMode == .trackUp) ? .northUp : .trackUp
            updateState()
        }
    }

    private func startSnapshotConsumer() {
        let snapshots = navigationEngine.snapshots
        snapshotTask = Task { [weak self] in
            for await snapshot in snapshots {
                guard let self, !Task.isCancelled else { break }
                var mapped = self.mapper.map(navigationSnapshot: snapshot)
                mapped = RouteMapViewState(
                    routePolyline: mapped.routePolyline,
                    traveledPolyline: mapped.traveledPolyline,
                    currentPosition: mapped.currentPosition,
                    startMarker: mapped.startMarker,
                    finishMarker: mapped.finishMarker,
                    cueMarkers: mapped.cueMarkers,
                    viewport: mapped.viewport,
                    orientation: MapOrientationState(headingDegrees: mapped.orientation.headingDegrees, mode: self.orientationMode)
                )
                self.state = mapped
            }
        }
    }

    private func updateState() {
        var mapped = mapper.map(navigationSnapshot: navigationEngine.currentSnapshot)
        mapped = RouteMapViewState(
            routePolyline: mapped.routePolyline,
            traveledPolyline: mapped.traveledPolyline,
            currentPosition: mapped.currentPosition,
            startMarker: mapped.startMarker,
            finishMarker: mapped.finishMarker,
            cueMarkers: mapped.cueMarkers,
            viewport: mapped.viewport,
            orientation: MapOrientationState(headingDegrees: mapped.orientation.headingDegrees, mode: orientationMode)
        )
        state = mapped
    }
}
