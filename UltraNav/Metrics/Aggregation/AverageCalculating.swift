import Foundation

protocol AverageCalculating: Sendable {
    func calculateAverage(samples: [Double]) -> Double?
}

struct SimpleAverageCalculator: AverageCalculating, Sendable {
    func calculateAverage(samples: [Double]) -> Double? {
        guard !samples.isEmpty else { return nil }
        let sum = samples.reduce(0.0, +)
        return sum / Double(samples.count)
    }
}
