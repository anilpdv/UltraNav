import Foundation

enum MetricsInput: Equatable, Sendable {
    case location(LocationSample)
    case gps(GPSAcceptedSample)
    case workout(WorkoutMetric)
    case sensor(sensor: SensorIdentifier, sample: SensorSample)
}

enum MetricsEngineCommand: Equatable, Sendable {
    case start(at: Date? = nil)
    case pause(at: Date? = nil)
    case resume(at: Date? = nil)
    case stop(at: Date? = nil)
    case finish(at: Date? = nil)
    case reset

    static let start: MetricsEngineCommand = .start(at: nil)
    static let pause: MetricsEngineCommand = .pause(at: nil)
    static let resume: MetricsEngineCommand = .resume(at: nil)
    static let stop: MetricsEngineCommand = .stop(at: nil)
    static let finish: MetricsEngineCommand = .finish(at: nil)
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
