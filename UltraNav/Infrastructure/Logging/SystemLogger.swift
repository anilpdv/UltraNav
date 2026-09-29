import Foundation
import OSLog

actor SystemLogger: Logging {
    private let subsystem: String
    private var loggers: [LogCategory: os.Logger] = [:]

    init(subsystem: String = "com.ultranav.app") {
        self.subsystem = subsystem
    }

    private func logger(for category: LogCategory) -> os.Logger {
        if let existing = loggers[category] {
            return existing
        }
        let created = os.Logger(subsystem: subsystem, category: category.rawValue)
        loggers[category] = created
        return created
    }

    func log(
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [LogMetadataEntry]
    ) async {
        let osLogger = logger(for: category)
        let formattedMessage = format(message: message, metadata: metadata)

        switch level {
        case .trace, .debug:
            osLogger.debug("\(formattedMessage, privacy: .public)")
        case .information:
            osLogger.info("\(formattedMessage, privacy: .public)")
        case .notice:
            osLogger.notice("\(formattedMessage, privacy: .public)")
        case .warning:
            osLogger.warning("\(formattedMessage, privacy: .public)")
        case .error:
            osLogger.error("\(formattedMessage, privacy: .public)")
        case .critical:
            osLogger.fault("\(formattedMessage, privacy: .public)")
        }
    }

    private func format(message: String, metadata: [LogMetadataEntry]) -> String {
        guard !metadata.isEmpty else { return message }
        let metadataString = metadata.map { entry in
            "\(entry.key)=\(entry.renderedValue(redactingSensitive: true))"
        }.joined(separator: " ")
        return "\(message) [\(metadataString)]"
    }
}
