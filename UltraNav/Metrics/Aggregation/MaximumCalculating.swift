import Foundation

protocol MaximumCalculating: Sendable {
    func calculateMaximum(samples: [Double]) -> Double?
}

struct SimpleMaximumCalculator: MaximumCalculating, Sendable {
    func calculateMaximum(samples: [Double]) -> Double? {
        samples.max()
    }
}
