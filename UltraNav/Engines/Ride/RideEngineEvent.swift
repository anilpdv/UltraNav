import Foundation

enum RideEngineEvent: Equatable, Sendable {
    case command(RideEngineCommand)
    case location(LocationServiceEvent)
    case workout(WorkoutServiceEvent)
    case sensor(SensorServiceEvent)
}
