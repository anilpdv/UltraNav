import Foundation

protocol FailureRecording: Sendable {
    func record(_ record: FailureRecord) async
    func recentFailures(limit: Int) async -> [FailureRecord]
    func clearResolvedFailures() async
}
