import Foundation

struct AutomaticRetryPolicy: Equatable, Sendable {
    let maximumAttempts: Int
    let initialDelaySeconds: TimeInterval
    let multiplier: Double
    let maximumDelaySeconds: TimeInterval

    init(
        maximumAttempts: Int = 3,
        initialDelaySeconds: TimeInterval = 1.0,
        multiplier: Double = 2.0,
        maximumDelaySeconds: TimeInterval = 30.0
    ) {
        self.maximumAttempts = maximumAttempts
        self.initialDelaySeconds = initialDelaySeconds
        self.multiplier = multiplier
        self.maximumDelaySeconds = maximumDelaySeconds
    }

    func delay(forAttempt attempt: Int) -> TimeInterval? {
        guard attempt < maximumAttempts else { return nil }
        let calculated = initialDelaySeconds * pow(multiplier, Double(attempt))
        return min(calculated, maximumDelaySeconds)
    }

    static let immediate = AutomaticRetryPolicy(maximumAttempts: 1, initialDelaySeconds: 0, multiplier: 1, maximumDelaySeconds: 0)
    static let sensors = AutomaticRetryPolicy(maximumAttempts: 5, initialDelaySeconds: 2.0, multiplier: 1.5, maximumDelaySeconds: 15.0)
    static let location = AutomaticRetryPolicy(maximumAttempts: 3, initialDelaySeconds: 1.0, multiplier: 2.0, maximumDelaySeconds: 10.0)
    static let disabled = AutomaticRetryPolicy(maximumAttempts: 0, initialDelaySeconds: 0, multiplier: 1, maximumDelaySeconds: 0)
}
