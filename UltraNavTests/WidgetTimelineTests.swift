import XCTest
import WidgetKit

final class WidgetTimelineTests: XCTestCase {
    func testTimelineContainsActionableEntryAndRefreshesHourly() {
        let now = Date(timeIntervalSince1970: 1_000)
        let timeline = UltraNavTimelineProvider.makeTimeline(now: now)

        XCTAssertEqual(timeline.entries.count, 1)
        XCTAssertEqual(timeline.entries[0].date, now)
        XCTAssertEqual(timeline.entries[0].title, "Navigate")
        XCTAssertEqual(
            timeline.entries[0].destinationURL.absoluteString,
            "ultranav://navigate"
        )
    }
}