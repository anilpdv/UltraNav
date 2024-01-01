import SwiftUI
import WidgetKit

@main
struct UltraNavWidgetBundle: WidgetBundle {
    var body: some Widget {
        AppleWatchWidget()
    }
}

struct AppleWatchWidget: Widget {
    let kind = "AppleWatchWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: UltraNavTimelineProvider()
        ) { entry in
            UltraNavWidgetEntryView(entry: entry)
                .widgetURL(entry.destinationURL)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Quick Navigate")
        .description("Open UltraNav directly from your watch face.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
            .accessoryRectangular
        ])
    }
}

private struct UltraNavWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UltraNavEntry

    var body: some View {
        switch family {
        case .accessoryInline:
            Label(entry.title, systemImage: "location.fill")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "location.fill")
                    .font(.title3)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Open UltraNav navigation")

        case .accessoryCorner:
            Image(systemName: "location.fill")
                .font(.title3)
                .widgetLabel {
                    Text(entry.title)
                }
                .accessibilityLabel("Open UltraNav navigation")

        default:
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(entry.detail)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(entry.title), \(entry.detail)")
        }
    }
}

#Preview(as: .accessoryRectangular) {
    AppleWatchWidget()
} timeline: {
    UltraNavEntry.placeholder
}