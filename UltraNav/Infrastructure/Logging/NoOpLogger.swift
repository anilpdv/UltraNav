import Foundation

struct NoOpLogger: Logging, Sendable {
    func log(
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [LogMetadataEntry]
    ) async {}
}
