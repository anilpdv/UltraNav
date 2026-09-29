import Foundation

/// Strongly typed failures across the complete route import pipeline.
public enum RouteImportFailure: Error, Equatable, Sendable {
    case fileTooLarge(sizeBytes: Int, limitBytes: Int)
    case readFailed(String)
    case parsingFailed(GPXParserFailure)
    case validationFailed(ParsedRouteValidationFailure)
    case normalizationFailed(RouteNormalizationFailure)
    case domainValidationFailed(RouteValidationFailure)
    case unknown(String)
}
