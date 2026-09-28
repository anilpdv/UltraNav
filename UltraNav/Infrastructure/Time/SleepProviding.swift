import Foundation

protocol SleepProviding: Sendable {
    func sleep(
        for duration: Duration
    ) async throws
}

struct SystemSleeper: SleepProviding, Sendable {
    func sleep(
        for duration: Duration
    ) async throws {
        try await Task.sleep(for: duration)
    }
}
