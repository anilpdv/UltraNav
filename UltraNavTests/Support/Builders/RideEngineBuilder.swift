import Foundation
@testable import UltraNav

@MainActor
final class RideEngineBuilder {
    var location: any LocationProviding = FakeLocationProvider()
    var workout: any WorkoutProviding = FakeWorkoutProvider()
    var sensors: any SensorProviding = FakeSensorProvider()
    var clock: any ClockProviding = TestClock()
    var dependencyPolicy: RideDependencyPolicy = .outdoorCycling

    func withLocation(_ location: any LocationProviding) -> Self {
        self.location = location
        return self
    }

    func withWorkout(_ workout: any WorkoutProviding) -> Self {
        self.workout = workout
        return self
    }

    func withSensors(_ sensors: any SensorProviding) -> Self {
        self.sensors = sensors
        return self
    }

    func withClock(_ clock: any ClockProviding) -> Self {
        self.clock = clock
        return self
    }

    func withDependencyPolicy(_ policy: RideDependencyPolicy) -> Self {
        self.dependencyPolicy = policy
        return self
    }

    func build() -> RideEngine {
        RideEngine(
            location: location,
            workout: workout,
            sensors: sensors,
            clock: clock,
            dependencyPolicy: dependencyPolicy
        )
    }
}
