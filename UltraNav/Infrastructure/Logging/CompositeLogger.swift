import Foundation

struct CompositeLogger: Logging, Sendable {
    private let loggers: [any Logging]

    init(loggers: [any Logging]) {
        self.loggers = loggers
    }

    func log(
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [LogMetadataEntry]
    ) async {
        for logger in loggers {
            await logger.log(level: level, category: category, message: message, metadata: metadata)
        }
    }
}
