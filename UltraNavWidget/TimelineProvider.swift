import WidgetKit
import OSLog
import Foundation

private let widgetLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "com.example.UltraNav.widget",
    category: "widgets"
)

struct UltraNavEntry: TimelineEntry {
    let date: Date
    let title: String
    let detail: String
    let destinationURL: URL
    let isPlaceholder: Bool

    static let placeholder = UltraNavEntry(
        date: .now,
        title: "Navigate",
        detail: "Open UltraNav",
        destinationURL: URL(string: "ultranav://navigate")!,
        isPlaceholder: true
    )
}

struct UltraNavTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UltraNavEntry {
        .placeholder
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (UltraNavEntry) -> Void
    ) {
        completion(
            UltraNavEntry(
                date: .now,
                title: "Navigate",
                detail: context.isPreview ? "Ready when you are" : "Open UltraNav",
                destinationURL: URL(string: "ultranav://navigate")!,
                isPlaceholder: context.isPreview
            )
        )
    }

    static func nextRefreshDate(after date: Date) -> Date {
        Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: date
        ) ?? date.addingTimeInterval(3_600)
    }

    static func makeTimeline(now: Date = .now) -> Timeline<UltraNavEntry> {
        let entry = UltraNavEntry(
            date: now,
            title: "Navigate",
            detail: "Open UltraNav",
            destinationURL: URL(string: "ultranav://navigate")!,
            isPlaceholder: false
        )
        return Timeline(
            entries: [entry],
            policy: .after(nextRefreshDate(after: now))
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<UltraNavEntry>) -> Void
    ) {
        completion(Self.makeTimeline())
    }
}