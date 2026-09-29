import Foundation

/// Protocol isolating GPS stream processing, lifecycle commands, and diagnostic snapshots.
protocol GPSProcessing: Sendable {
    func send(_ command: GPSProcessorCommand) async
    func process(_ sample: LocationSample, receivedAt: Date) async -> GPSProcessingResult
    func snapshot() async -> GPSProcessingSnapshot
}
