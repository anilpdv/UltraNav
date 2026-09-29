import Foundation

enum MetricsInput: Equatable, Sendable {
    case location(LocationSample)
    case workout(WorkoutMetric)
    case sensor(SensorIdentifier, SensorSample)
}

enum MetricsEngineCommand: Equatable, Sendable {
    case start
    case pause
    case resume
    case stop
    case reset
}

@MainActor
protocol MetricsEngineProviding: Sendable {
    var currentSnapshot: MetricsSnapshot { get }
    var snapshots: AsyncStream<MetricsSnapshot> { get }

    func send(_ command: MetricsEngineCommand) async
    func consume(location: LocationSample)
    func consume(workout: WorkoutMetric)
    func consume(sensor: SensorIdentifier, sample: SensorSample)
}
