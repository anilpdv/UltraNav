import Foundation

public enum RouteLibraryPhaseViewState: String, Codable, Equatable, Sendable {
    case loading
    case ready
    case importing
    case deleting
    case failed
}

public struct RouteRowViewState: Identifiable, Equatable, Sendable {
    public let id: Route.ID
    public let name: String
    public let distance: MetricDisplayValue
    public let pointCountText: String
    public let elevationAvailabilityText: String?
    public let isSelected: Bool
    public let canDelete: Bool
    public let accessibilityLabel: String

    public init(
        id: Route.ID,
        name: String,
        distance: MetricDisplayValue,
        pointCountText: String = "",
        elevationAvailabilityText: String? = nil,
        isSelected: Bool = false,
        canDelete: Bool = true,
        accessibilityLabel: String = ""
    ) {
        self.id = id
        self.name = name
        self.distance = distance
        self.pointCountText = pointCountText
        self.elevationAvailabilityText = elevationAvailabilityText
        self.isSelected = isSelected
        self.canDelete = canDelete
        self.accessibilityLabel = accessibilityLabel
    }
}

public struct RouteLibraryViewState: Equatable, Sendable {
    public let phase: RouteLibraryPhaseViewState
    public let routes: [RouteRowViewState]
    public let selectedRouteID: Route.ID?
    public let importStageText: String?
    public let warningMessages: [String]
    public let emptyState: EmptyStateViewState?
    public let alert: AlertViewState?

    public init(
        phase: RouteLibraryPhaseViewState,
        routes: [RouteRowViewState] = [],
        selectedRouteID: Route.ID? = nil,
        importStageText: String? = nil,
        warningMessages: [String] = [],
        emptyState: EmptyStateViewState? = nil,
        alert: AlertViewState? = nil
    ) {
        self.phase = phase
        self.routes = routes
        self.selectedRouteID = selectedRouteID
        self.importStageText = importStageText
        self.warningMessages = warningMessages
        self.emptyState = emptyState
        self.alert = alert
    }

    public static let initial = RouteLibraryViewState(phase: .loading)
}

public enum RouteLibraryPresentationAction: Equatable, Sendable {
    case appeared
    case importSelected
    case importSourceReceived(RouteImportSource)
    case routeSelected(Route.ID)
    case routeDeleteRequested(Route.ID)
    case routeDeleteConfirmed(Route.ID)
    case routeDeleteCancelled
    case errorDismissed
}
