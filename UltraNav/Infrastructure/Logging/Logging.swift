import Foundation

protocol Logging: Sendable {
    func log(
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [LogMetadataEntry]
    ) async
}

extension Logging {
    func trace(
        category: LogCategory,
        _ message: String,
        metadata: [LogMetadataEntry] = []
    ) async {
        await log(level: .trace, category: category, message: message, metadata: metadata)
    }

    func debug(
        category: LogCategory,
        _ message: String,
        metadata: [LogMetadataEntry] = []
    ) async {
        await log(level: .debug, category: category, message: message, metadata: metadata)
    }

    func information(
        category: LogCategory,
        _ message: String,
        metadata: [LogMetadataEntry] = []
    ) async {
        await log(level: .information, category: category, message: message, metadata: metadata)
    }

    func notice(
        category: LogCategory,
        _ message: String,
        metadata: [LogMetadataEntry] = []
    ) async {
        await log(level: .notice, category: category, message: message, metadata: metadata)
    }

    func warning(
        category: LogCategory,
        _ message: String,
        metadata: [LogMetadataEntry] = []
    ) async {
        await log(level: .warning, category: category, message: message, metadata: metadata)
    }

    func error(
        category: LogCategory,
        _ message: String,
        metadata: [LogMetadataEntry] = []
    ) async {
        await log(level: .error, category: category, message: message, metadata: metadata)
    }

    func critical(
        category: LogCategory,
        _ message: String,
        metadata: [LogMetadataEntry] = []
    ) async {
        await log(level: .critical, category: category, message: message, metadata: metadata)
    }
}
