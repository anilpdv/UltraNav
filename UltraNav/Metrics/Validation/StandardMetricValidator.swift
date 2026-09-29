import Foundation

protocol MetricValidating: Sendable {
    func validate(observation: MetricObservation) -> Bool
}

struct StandardMetricValidator: MetricValidating, Sendable {
    func validate(observation: MetricObservation) -> Bool {
        switch observation.value {
        case .speed(let mps):
            return mps.isFinite && mps >= 0 && mps <= 70.0 // up to 250 km/h
        case .heartRate(let bpm):
            return bpm >= 30 && bpm <= 260
        case .cadence(let rpm):
            return rpm.isFinite && rpm >= 0 && rpm <= 250.0
        case .power(let watts):
            return watts >= 0 && watts <= 3000
        case .distance(let meters):
            return meters.isFinite && meters >= 0
        case .altitude(let meters):
            return meters.isFinite && meters >= -500 && meters <= 9000
        case .energy(let kcal):
            return kcal.isFinite && kcal >= 0
        }
    }
}
