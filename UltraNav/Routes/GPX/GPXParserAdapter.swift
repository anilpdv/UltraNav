import Foundation

/// Production-ready conforming implementation of GPXParsing.
/// Uses a streaming XMLParser with safety limits, namespace resolution, and comprehensive reporting.
public final class GPXParserAdapter: GPXParsing, Sendable {
    private let policy: GPXParsingPolicy
    private let limits: GPXParserLimits

    public init(
        policy: GPXParsingPolicy = .standard,
        limits: GPXParserLimits = .watchStandard
    ) {
        self.policy = policy
        self.limits = limits
    }

    public func parseReport(data: Data, sourceMetadata: GPXSourceMetadata?) async throws -> GPXParsingReport {
        try Task.checkCancellation()

        guard !data.isEmpty else {
            throw GPXParserFailure.emptyDocument
        }

        if data.count > limits.maximumFileBytes {
            throw GPXParserFailure.fileTooLarge(bytes: data.count, limit: limits.maximumFileBytes)
        }

        let delegate = GPXParserDelegate(
            policy: policy,
            limits: limits,
            sourceMetadata: sourceMetadata
        )

        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = true
        parser.shouldResolveExternalEntities = false

        guard parser.parse() else {
            if let fatal = delegate.fatalError {
                throw fatal
            }
            if let error = parser.parserError {
                let nsError = error as NSError
                throw GPXParserFailure.xmlParserError(code: nsError.code, description: nsError.localizedDescription)
            }
            throw GPXParserFailure.malformedXML(message: "Failed to parse XML stream")
        }

        if let fatal = delegate.fatalError {
            throw fatal
        }

        try Task.checkCancellation()

        let report = delegate.buildReport()

        // Check if there is any supported content at all
        let doc = report.document
        if doc.tracks.isEmpty && doc.routes.isEmpty && doc.waypoints.isEmpty {
            throw GPXParserFailure.noSupportedContent
        }

        return report
    }
}
