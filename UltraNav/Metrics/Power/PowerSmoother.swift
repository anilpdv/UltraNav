import Foundation

struct PowerSmoothingConfiguration: Equatable, Sendable {
    let windowsSeconds: [TimeInterval]
    let maximumSampleGapSeconds: TimeInterval

    static let standard = PowerSmoothingConfiguration(
        windowsSeconds: [3.0, 10.0, 30.0],
        maximumSampleGapSeconds: 3.0
    )
}

struct PowerSmoother: Sendable {
    private struct PowerSample: Equatable, Sendable {
        let watts: Double
        let timestamp: Date
    }

    private var samples: [PowerSample] = []
    private let maxRetentionSeconds: TimeInterval

    init(maxRetentionSeconds: TimeInterval = 35.0) {
        self.maxRetentionSeconds = maxRetentionSeconds
    }

    mutating func consume(watts: Double, at timestamp: Date) {
        guard watts.isFinite else { return }
        samples.append(PowerSample(watts: watts, timestamp: timestamp))

        let cutoff = timestamp.addingTimeInterval(-maxRetentionSeconds)
        samples.removeAll { $0.timestamp < cutoff }
    }

    func average(windowSeconds: TimeInterval, at timestamp: Date, maxGapSeconds: TimeInterval = 3.0) -> Double? {
        let cutoff = timestamp.addingTimeInterval(-windowSeconds)
        let windowSamples = samples.filter { $0.timestamp >= cutoff && $0.timestamp <= timestamp }

        guard !windowSamples.isEmpty else { return nil }

        if windowSamples.count == 1 {
            let age = timestamp.timeIntervalSince(windowSamples[0].timestamp)
            return age <= maxGapSeconds ? windowSamples[0].watts : nil
        }

        var weightedSum: Double = 0
        var totalDuration: TimeInterval = 0

        for i in 0..<(windowSamples.count - 1) {
            let current = windowSamples[i]
            let next = windowSamples[i + 1]
            let dt = next.timestamp.timeIntervalSince(current.timestamp)
            if dt > 0 && dt <= maxGapSeconds {
                weightedSum += next.watts * dt
                totalDuration += dt
            }
        }

        guard totalDuration > 0 else {
            return windowSamples.last?.watts
        }

        return weightedSum / totalDuration
    }

    mutating func reset() {
        samples.removeAll()
    }
}
