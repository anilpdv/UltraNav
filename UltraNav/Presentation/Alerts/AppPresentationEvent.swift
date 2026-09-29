import Foundation

public enum AppPresentationEvent: Equatable, Sendable {
    case showAlert(AlertViewState)
    case showBanner(BannerViewState)
    case dismissBanner(BannerViewState.ID)
    case presentRouteImporter
    case navigateToRideSummary
}

public struct EmptyStateViewState: Equatable, Sendable {
    public let title: String
    public let message: String
    public let actionTitle: String?

    public init(title: String, message: String, actionTitle: String? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
    }
}
