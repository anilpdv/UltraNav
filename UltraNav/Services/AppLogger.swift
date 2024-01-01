import Foundation
import OSLog

enum AppLogger {
    private static let subsystem =
        Bundle.main.bundleIdentifier ?? "com.example.UltraNav"

    static let lifecycle = Logger(
        subsystem: subsystem,
        category: "lifecycle"
    )

    static let networking = Logger(
        subsystem: subsystem,
        category: "networking"
    )

    static let persistence = Logger(
        subsystem: subsystem,
        category: "persistence"
    )

    static let sync = Logger(
        subsystem: subsystem,
        category: "sync"
    )

    static let widgets = Logger(
        subsystem: subsystem,
        category: "widgets"
    )

    static let notifications = Logger(
        subsystem: subsystem,
        category: "notifications"
    )
}
