import Foundation

public enum MetricDisplayAvailability: String, Codable, Equatable, Sendable {
    case available
    case stale
    case unavailable
    case invalid
}

public struct MetricDisplayValue: Equatable, Sendable {
    public let primaryText: String
    public let unitText: String
    public let sourceText: String?
    public let availability: MetricDisplayAvailability
    public let accessibilityLabel: String
    public let accessibilityValue: String

    public init(
        primaryText: String,
        unitText: String,
        sourceText: String? = nil,
        availability: MetricDisplayAvailability = .available,
        accessibilityLabel: String,
        accessibilityValue: String
    ) {
        self.primaryText = primaryText
        self.unitText = unitText
        self.sourceText = sourceText
        self.availability = availability
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityValue = accessibilityValue
    }

    public static func unavailable(
        unit: String,
        label: String,
        placeholder: String = "--"
    ) -> MetricDisplayValue {
        MetricDisplayValue(
            primaryText: placeholder,
            unitText: unit,
            sourceText: nil,
            availability: .unavailable,
            accessibilityLabel: label,
            accessibilityValue: "Not available"
        )
    }

    public static func stale(
        primaryText: String,
        unit: String,
        label: String
    ) -> MetricDisplayValue {
        MetricDisplayValue(
            primaryText: primaryText,
            unitText: unit,
            sourceText: nil,
            availability: .stale,
            accessibilityLabel: label,
            accessibilityValue: "\(primaryText) \(unit) stale"
        )
    }
}
