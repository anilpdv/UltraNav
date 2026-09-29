import Foundation

enum MetricsInput: Equatable, Sendable {
    case location(LocationSample)
    case gps(GPSAcceptedSample)
    case workout(WorkoutMetric)
    case sensor(sensor: SensorIdentifier, sample: SensorSample)
    case tick(Date)
}

@MainActor
protocol MetricsEngineProviding: AnyObject, Sendable {
    var currentSnapshot: MetricsSnapshot { get }
    var snapshots: AsyncStream<MetricsSnapshot> { get }

    func send(_ command: MetricsEngineCommand) async
    func consume(location: LocationSample)
    func consume(gps: GPSAcceptedSample)
    func consume(workout: WorkoutMetric)
    func consume(sensor: SensorIdentifier, sample: SensorSample)
    func consume(_ input: MetricsInput)
}
