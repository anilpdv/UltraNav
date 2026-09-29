import Foundation

public struct RouteLibraryViewStateMapper: Sendable {
    private let distanceFormatter: any DistanceFormatting

    public init(distanceFormatter: any DistanceFormatting = StandardDistanceFormatter()) {
        self.distanceFormatter = distanceFormatter
    }

    func map(
        snapshot: RouteLibrarySnapshot,
        activeRouteID: Route.ID? = nil,
        pendingDeleteRouteID: Route.ID? = nil,
        preferences: UnitPreferences = .default
    ) -> RouteLibraryViewState {
        let phase = mapPhase(snapshot.state)
        let routes = snapshot.routes.map { summary in
            mapRow(
                summary,
                isSelected: summary.id == snapshot.selectedRouteID,
                isActive: summary.id == (activeRouteID ?? snapshot.activeRouteID),
                preferences: preferences
            )
        }

        let emptyState: EmptyStateViewState?
        if routes.isEmpty && phase == .ready {
            emptyState = EmptyStateViewState(
                title: "No Routes",
                message: "Import a GPX route from your files to begin navigating.",
                actionTitle: "Import Route"
            )
        } else {
            emptyState = nil
        }

        let alert: AlertViewState?
        if let pendingID = pendingDeleteRouteID,
           let routeToDelete = snapshot.routes.first(where: { $0.id == pendingID }) {
            alert = AlertViewState(
                id: .init(rawValue: "delete-route-\(pendingID)"),
                title: "Delete Route?",
                message: "Are you sure you want to delete \(routeToDelete.name)?",
                primaryAction: .init(title: "Delete", role: .destructive),
                secondaryAction: .init(title: "Cancel", role: .cancel)
            )
        } else if let failure = snapshot.failure {
            alert = AlertViewState(
                id: .init(rawValue: "route-error"),
                title: "Route Error",
                message: failureMessage(failure),
                primaryAction: .init(title: "OK", role: .standard)
            )
        } else {
            alert = nil
        }

        return RouteLibraryViewState(
            phase: phase,
            routes: routes,
            selectedRouteID: snapshot.selectedRouteID,
            importStageText: snapshot.state == .importing ? "Importing GPX route..." : nil,
            warningMessages: [],
            emptyState: emptyState,
            alert: alert
        )
    }

    private func mapPhase(_ state: RouteLibraryState) -> RouteLibraryPhaseViewState {
        switch state {
        case .idle, .loading: return .loading
        case .ready: return .ready
        case .importing: return .importing
        case .deleting: return .deleting
        case .failed: return .failed
        }
    }

    private func mapRow(
        _ summary: RouteSummary,
        isSelected: Bool,
        isActive: Bool,
        preferences: UnitPreferences
    ) -> RouteRowViewState {
        let dist = distanceFormatter.formatDistance(meters: summary.totalDistanceMeters, preferences: preferences)
        let pointText = "\(summary.pointCount) pts"
        let elevText = summary.hasElevation ? "Elevation data included" : "No elevation"
        let canDelete = !isActive

        let label = "\(summary.name), \(dist.accessibilityValue), \(pointText)"

        return RouteRowViewState(
            id: summary.id,
            name: summary.name,
            distance: dist,
            pointCountText: pointText,
            elevationAvailabilityText: elevText,
            isSelected: isSelected,
            canDelete: canDelete,
            accessibilityLabel: label
        )
    }

    private func failureMessage(_ failure: RouteLibraryFailure) -> String {
        switch failure {
        case .loadFailed(let msg): return "Failed to load route: \(msg)"
        case .importFailed(let err): return "Route import failed: \(err)"
        case .deleteFailed(let msg): return "Failed to delete route: \(msg)"
        case .activeRouteProtected: return "Active route cannot be deleted."
        }
    }
}
