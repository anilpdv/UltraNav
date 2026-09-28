import Foundation

struct RideDegradation: OptionSet, Equatable, Sendable {
    let rawValue: Int

    static let locationUnavailable = RideDegradation(rawValue: 1 << 0)
    static let sensorsUnavailable = RideDegradation(rawValue: 1 << 1)
    static let workoutMetricsUnavailable = RideDegradation(rawValue: 1 << 2)

    init(rawValue: Int) {
        self.rawValue = rawValue
    }
}
