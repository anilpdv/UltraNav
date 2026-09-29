import Foundation

/// Coordinator executing the multi-stage GPX-to-Route import pipeline.
public final class RouteImporter: RouteImporting, Sendable {
    private let sourceReader: any RouteSourceReading
    private let parser: any GPXParsing
    private let parsedValidator: any ParsedRouteValidating
    private let normalizer: any RouteNormalizing
    private let routeValidator: any RouteValidating

    public init(
        sourceReader: any RouteSourceReading = StandardRouteSourceReader(),
        parser: any GPXParsing = GPXParserAdapter(),
        parsedValidator: any ParsedRouteValidating = ParsedRouteValidator(),
        normalizer: any RouteNormalizing = RouteNormalizer(),
        routeValidator: any RouteValidating = CanonicalRouteValidator()
    ) {
        self.sourceReader = sourceReader
        self.parser = parser
        self.parsedValidator = parsedValidator
        self.normalizer = normalizer
        self.routeValidator = routeValidator
    }

    public func importRoute(
        from source: RouteImportSource,
        policy: RouteImportPolicy = .default
    ) async throws -> RouteImportResult {
        try Task.checkCancellation()

        // 1. Read source data
        let content: RouteSourceContent
        do {
            content = try await sourceReader.read(from: source)
        } catch let err as RouteSourceReadFailure {
            throw RouteImportFailure.readFailed("\(err)")
        } catch {
            throw RouteImportFailure.readFailed(error.localizedDescription)
        }

        // 2. Enforce byte size limits
        if content.data.count > policy.limits.maxFileSizeBytes {
            throw RouteImportFailure.fileTooLarge(
                sizeBytes: content.data.count,
                limitBytes: policy.limits.maxFileSizeBytes
            )
        }

        // 3. Parse GPX XML & gather parser warnings
        let report: GPXParsingReport
        do {
            let meta = GPXSourceMetadata(originalFileName: content.fallbackName)
            report = try await parser.parseReport(data: content.data, sourceMetadata: meta)
        } catch let failure as GPXParserFailure {
            throw RouteImportFailure.parsingFailed(failure)
        } catch {
            throw RouteImportFailure.parsingFailed(.malformedXML(message: error.localizedDescription))
        }

        try Task.checkCancellation()

        // 4. Validate parsed document structure
        do {
            try parsedValidator.validate(document: report.document, policy: policy.validationPolicy)
        } catch let failure as ParsedRouteValidationFailure {
            throw RouteImportFailure.validationFailed(failure)
        } catch {
            throw RouteImportFailure.validationFailed(.noUsableCoordinates)
        }

        // 5. Normalize document into canonical domain Route
        let normResult: RouteNormalizationResult
        do {
            normResult = try normalizer.normalize(
                document: report.document,
                source: content.source,
                fallbackName: content.fallbackName,
                policy: policy.normalizationPolicy
            )
        } catch let failure as RouteNormalizationFailure {
            throw RouteImportFailure.normalizationFailed(failure)
        } catch {
            throw RouteImportFailure.normalizationFailed(.noPointsRemainingAfterFiltering)
        }

        try Task.checkCancellation()

        // 6. Validate domain invariants of normalized Route
        do {
            try routeValidator.validate(route: normResult.route)
        } catch let failure as RouteValidationFailure {
            throw RouteImportFailure.domainValidationFailed(failure)
        } catch {
            throw RouteImportFailure.domainValidationFailed(.emptyPoints)
        }

        return RouteImportResult(route: normResult.route, warnings: normResult.warnings)
    }
}
