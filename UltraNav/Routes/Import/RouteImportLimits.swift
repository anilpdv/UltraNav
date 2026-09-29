import Foundation

/// Safety thresholds to prevent OOM / WatchOS exhaustion during route import.
public struct RouteImportLimits: Equatable, Sendable {
    public let maxFileSizeBytes: Int
    public let maxParsedPointCount: Int

    public init(
        maxFileSizeBytes: Int = 25 * 1024 * 1024, // 25 MB
        maxParsedPointCount: Int = 500_000
    ) {
        self.maxFileSizeBytes = maxFileSizeBytes
        self.maxParsedPointCount = maxParsedPointCount
    }

    public static let `default` = RouteImportLimits()
}

/// Comprehensive policy governing the full import pipeline.
public struct RouteImportPolicy: Equatable, Sendable {
    public let limits: RouteImportLimits
    public let validationPolicy: ParsedRouteValidationPolicy
    public let normalizationPolicy: RouteNormalizationPolicy

    public init(
        limits: RouteImportLimits = .default,
        validationPolicy: ParsedRouteValidationPolicy = .default,
        normalizationPolicy: RouteNormalizationPolicy = .default
    ) {
        self.limits = limits
        self.validationPolicy = validationPolicy
        self.normalizationPolicy = normalizationPolicy
    }

    public static let `default` = RouteImportPolicy()
}
