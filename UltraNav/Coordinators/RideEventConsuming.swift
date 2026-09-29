import Foundation

@MainActor
protocol RideLocationEventConsuming: AnyObject, Sendable {
    func consume(locationEvent: LocationServiceEvent) async
}

@MainActor
protocol RideWorkoutEventConsuming: AnyObject, Sendable {
    func consume(workoutEvent: WorkoutServiceEvent) async
}

@MainActor
protocol RideSensorEventConsuming: AnyObject, Sendable {
    func consume(sensorEvent: SensorServiceEvent) async
}
