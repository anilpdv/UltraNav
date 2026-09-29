import Foundation
@testable import UltraNav

actor TestLogger: Logging {
    struct Entry: Equatable, Sendable {
        let level: LogLevel
        let category: LogCategory
        let message: String
        let metadata: [LogMetadataEntry]
    }

    private(set) var entries: [Entry] = []

    func log(
        level: LogLevel,
        category: LogCategory,
        message: String,
        metadata: [LogMetadataEntry]
    ) async {
        entries.append(
            Entry(
                level: level,
                category: category,
                message: message,
                metadata: metadata
            )
        )
    }

    func clear() {
        entries.removeAll()
    }
}
