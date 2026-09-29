import Foundation

/// Fixed deterministic date constants for reproducible test timelines.
enum TestDates {
    /// Fixed base ride start date: 2023-11-14 22:13:20 UTC (1_700_000_000).
    static let rideStart = Date(timeIntervalSince1970: 1_700_000_000)

    /// 1 second after ride start.
    static let oneSecondLater = rideStart.addingTimeInterval(1)

    /// 10 seconds after ride start.
    static let tenSecondsLater = rideStart.addingTimeInterval(10)

    /// 1 minute after ride start.
    static let oneMinuteLater = rideStart.addingTimeInterval(60)

    /// 5 minutes after ride start.
    static let fiveMinutesLater = rideStart.addingTimeInterval(300)

    /// 1 hour after ride start.
    static let oneHourLater = rideStart.addingTimeInterval(3_600)

    /// 2 hours after ride start.
    static let twoHoursLater = rideStart.addingTimeInterval(7_200)
}
