import XCTest
@testable import UltraNav

final class FormattingTests: XCTestCase {
    func testDurationFormatterFormatsSecondsMinutesHours() {
        let formatter = StandardDurationFormatter()
        
        XCTAssertEqual(formatter.formatDuration(seconds: 0), "00:00")
        XCTAssertEqual(formatter.formatDuration(seconds: 45), "00:45")
        XCTAssertEqual(formatter.formatDuration(seconds: 125), "02:05")
        XCTAssertEqual(formatter.formatDuration(seconds: 3661), "1:01:01")
    }

    func testSpeedFormatterMetricAndImperial() {
        let formatter = StandardSpeedFormatter()
        
        // 10 m/s = 36.0 km/h
        let metric = formatter.formatSpeed(metersPerSecond: 10.0, preferences: .metric)
        XCTAssertEqual(metric.primaryText, "36.0")
        XCTAssertEqual(metric.unitText, "km/h")
        XCTAssertEqual(metric.availability, .available)

        // 10 m/s ≈ 22.4 mph (10 * 2.23694)
        let imperial = formatter.formatSpeed(metersPerSecond: 10.0, preferences: .imperial)
        XCTAssertEqual(imperial.primaryText, "22.4")
        XCTAssertEqual(imperial.unitText, "mph")
        XCTAssertEqual(imperial.availability, .available)
    }

    func testDistanceFormatterShortAndLong() {
        let formatter = StandardDistanceFormatter()
        
        // Metric < 1000m -> meters
        let shortMetric = formatter.formatDistance(meters: 450, preferences: .metric)
        XCTAssertEqual(shortMetric.primaryText, "450")
        XCTAssertEqual(shortMetric.unitText, "m")

        // Metric >= 1000m -> kilometers
        let longMetric = formatter.formatDistance(meters: 12500, preferences: .metric)
        XCTAssertEqual(longMetric.primaryText, "12.5")
        XCTAssertEqual(longMetric.unitText, "km")

        // Imperial < 0.1 mi (160.9m) -> feet
        let shortImperial = formatter.formatDistance(meters: 100, preferences: .imperial)
        XCTAssertEqual(shortImperial.primaryText, "328")
        XCTAssertEqual(shortImperial.unitText, "ft")

        // Imperial >= 0.1 mi -> miles
        let longImperial = formatter.formatDistance(meters: 16093.4, preferences: .imperial)
        XCTAssertEqual(longImperial.primaryText, "10.0")
        XCTAssertEqual(longImperial.unitText, "mi")
    }

    func testElevationFormatterMetricAndImperial() {
        let formatter = StandardElevationFormatter()
        
        let metric = formatter.formatElevation(meters: 450.4, preferences: .metric)
        XCTAssertEqual(metric.primaryText, "450")
        XCTAssertEqual(metric.unitText, "m")

        let imperial = formatter.formatElevation(meters: 450.4, preferences: .imperial)
        XCTAssertEqual(imperial.primaryText, "1478")
        XCTAssertEqual(imperial.unitText, "ft")
    }

    func testGradientFormatter() {
        let formatter = StandardGradientFormatter()
        
        let positive = formatter.formatGradient(ratio: 0.085)
        XCTAssertEqual(positive.primaryText, "8.5")
        XCTAssertEqual(positive.unitText, "%")

        let negative = formatter.formatGradient(ratio: -0.042)
        XCTAssertEqual(negative.primaryText, "-4.2")
        XCTAssertEqual(negative.unitText, "%")

        let flat = formatter.formatGradient(ratio: 0.0)
        XCTAssertEqual(flat.primaryText, "0.0")
        XCTAssertEqual(flat.unitText, "%")
    }
}
