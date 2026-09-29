import Foundation

struct RollingSampleBuffer: Equatable, Sendable {
    private(set) var capacity: Int
    private(set) var observations: [MetricObservation] = []

    init(capacity: Int = 300) {
        self.capacity = max(1, capacity)
    }

    mutating func append(_ observation: MetricObservation) {
        observations.append(observation)
        if observations.count > capacity {
            observations.removeFirst(observations.count - capacity)
        }
    }

    func samples(within windowSeconds: TimeInterval, from now: Date) -> [MetricObservation] {
        let cutoff = now.addingTimeInterval(-windowSeconds)
        return observations.filter { $0.timestamp >= cutoff && $0.timestamp <= now }
    }

    mutating func prune(olderThan cutoff: Date) {
        observations.removeAll { $0.timestamp < cutoff }
    }

    mutating func clear() {
        observations.removeAll()
    }
}
