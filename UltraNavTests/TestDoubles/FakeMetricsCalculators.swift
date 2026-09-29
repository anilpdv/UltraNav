import Foundation
@testable import UltraNav

struct FakeAverageCalculator: AverageCalculating, Sendable {
    var stubbedAverage: Double?

    func calculateAverage(samples: [Double]) -> Double? {
        stubbedAverage ?? SimpleAverageCalculator().calculateAverage(samples: samples)
    }
}

struct FakeMaximumCalculator: MaximumCalculating, Sendable {
    var stubbedMaximum: Double?

    func calculateMaximum(samples: [Double]) -> Double? {
        stubbedMaximum ?? SimpleMaximumCalculator().calculateMaximum(samples: samples)
    }
}

struct FakeMetricValidator: MetricValidating, Sendable {
    var isValid: Bool = true

    func validate(observation: MetricObservation) -> Bool {
        isValid
    }
}

struct FakeMetricSourceSelector: MetricSourceSelecting, Sendable {
    var stubbedObservation: MetricObservation?

    func selectObservation(from candidates: [MetricObservation], now: Date) -> MetricObservation? {
        stubbedObservation ?? TemporaryLatestSourceSelector().selectObservation(from: candidates, now: now)
    }
}
