import Foundation

public enum BannerSeverity: String, Codable, Equatable, Sendable {
    case information
    case warning
    case critical
}

public struct BannerViewState: Identifiable, Equatable, Sendable {
    public struct ID: RawRepresentable, Hashable, Sendable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
    }

    public let id: ID
    public let severity: BannerSeverity
    public let title: String
    public let message: String?
    public let isDismissible: Bool

    public init(
        id: ID,
        severity: BannerSeverity,
        title: String,
        message: String? = nil,
        isDismissible: Bool = true
    ) {
        self.id = id
        self.severity = severity
        self.title = title
        self.message = message
        self.isDismissible = isDismissible
    }
}
