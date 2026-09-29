import Foundation

protocol PowerSmoothing: Sendable {
    func smoothPower(samples: [MetricObservation], windowSeconds: TimeInterval, now: Date) -> Double?
}

struct LegacyPowerSmoothing: PowerSmoothing, Sendable {
    func smoothPower(samples: [MetricObservation], windowSeconds: TimeInterval = 3.0, now: Date) -> Double? {
        let cutoff = now.addingTimeInterval(-windowSeconds)
        let relevant = samples.filter { sample in
            sample.timestamp >= cutoff && sample.timestamp <= now
        }.compactMap { sample -> Double? in
            if case .power(let watts) = sample.value {
                return Double(watts)
            }
            return nil
        }

        guard !relevant.isEmpty else { return nil }
        let sum = relevant.reduce(0.0, +)
        return sum / Double(relevant.count)
    }
}
