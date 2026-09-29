import Foundation

/// Policy controlling how invalid or optional fields are handled during GPX parsing.
public struct GPXParsingPolicy: Equatable, Sendable {
    public enum InvalidOptionalValueBehavior: Equatable, Sendable {
        case discardValue
        case rejectPoint
        case rejectDocument
    }

    public enum InvalidRequiredValueBehavior: Equatable, Sendable {
        case rejectPoint
        case rejectDocument
    }

    public let invalidElevationBehavior: InvalidOptionalValueBehavior
    public let invalidTimestampBehavior: InvalidOptionalValueBehavior
    public let invalidCoordinateBehavior: InvalidRequiredValueBehavior
    public let preserveUnknownExtensions: Bool

    public init(
        invalidElevationBehavior: InvalidOptionalValueBehavior = .discardValue,
        invalidTimestampBehavior: InvalidOptionalValueBehavior = .discardValue,
        invalidCoordinateBehavior: InvalidRequiredValueBehavior = .rejectPoint,
        preserveUnknownExtensions: Bool = false
    ) {
        self.invalidElevationBehavior = invalidElevationBehavior
        self.invalidTimestampBehavior = invalidTimestampBehavior
        self.invalidCoordinateBehavior = invalidCoordinateBehavior
        self.preserveUnknownExtensions = preserveUnknownExtensions
    }

    public static let standard = GPXParsingPolicy(
        invalidElevationBehavior: .discardValue,
        invalidTimestampBehavior: .discardValue,
        invalidCoordinateBehavior: .rejectPoint,
        preserveUnknownExtensions: false
    )
}
