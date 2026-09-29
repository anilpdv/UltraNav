import Foundation
import OSLog

struct FailureDiagnostics: Sendable {
    private static let logger = Logger(subsystem: "com.ultranav.app", category: "Errors")

    static func log(record: FailureRecord) {
        let id = record.failureID.rawValue
        let severity = String(describing: record.severity)
        let operation = String(describing: record.context.operation)
        let diagnostic = record.diagnosticMessage ?? "No diagnostic message"

        switch record.severity {
        case .informational:
            logger.info("[\(id)] [\(severity)] Op: \(operation) - \(diagnostic) (Occurrences: \(record.occurrenceCount))")
        case .warning:
            logger.warning("[\(id)] [\(severity)] Op: \(operation) - \(diagnostic) (Occurrences: \(record.occurrenceCount))")
        case .high, .critical:
            logger.error("[\(id)] [\(severity)] Op: \(operation) - \(diagnostic) (Occurrences: \(record.occurrenceCount))")
        }
    }
}
