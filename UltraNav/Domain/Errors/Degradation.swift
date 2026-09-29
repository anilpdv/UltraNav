import Foundation

struct Degradation: OptionSet, Equatable, Hashable, Sendable {
    let rawValue: Int

    static let locationUnavailable = Degradation(rawValue: 1 << 0)
    static let sensorsUnavailable = Degradation(rawValue: 1 << 1)
    static let heartRateUnavailable = Degradation(rawValue: 1 << 2)
    static let powerUnavailable = Degradation(rawValue: 1 << 3)
    static let cadenceUnavailable = Degradation(rawValue: 1 << 4)
    static let navigationUnavailable = Degradation(rawValue: 1 << 5)
    static let climbDataUnavailable = Degradation(rawValue: 1 << 6)
    static let healthKitMetricsUnavailable = Degradation(rawValue: 1 << 7)
    static let workoutNotSaved = Degradation(rawValue: 1 << 8)

    static let none: Degradation = []
}

struct ActiveDegradation: Identifiable, Equatable, Sendable {
    let id: FailureID
    let degradation: Degradation
    let startedAt: Date
    let lastUpdatedAt: Date
    let occurrenceCount: Int

    init(
        id: FailureID,
        degradation: Degradation,
        startedAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        occurrenceCount: Int = 1
    ) {
        self.id = id
        self.degradation = degradation
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.occurrenceCount = occurrenceCount
    }
}
