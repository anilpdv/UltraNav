import Foundation

public enum AlertActionRole: String, Codable, Equatable, Sendable {
    case standard
    case cancel
    case destructive
}

public struct AlertActionViewState: Equatable, Sendable {
    public let title: String
    public let role: AlertActionRole

    public init(title: String, role: AlertActionRole = .standard) {
        self.title = title
        self.role = role
    }
}

public struct AlertViewState: Identifiable, Equatable, Sendable {
    public struct ID: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let title: String
    public let message: String
    public let primaryAction: AlertActionViewState
    public let secondaryAction: AlertActionViewState?

    public init(
        id: ID,
        title: String,
        message: String,
        primaryAction: AlertActionViewState,
        secondaryAction: AlertActionViewState? = nil
    ) {
        self.id = id
        self.title = title
        self.message = message
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
    }
}
