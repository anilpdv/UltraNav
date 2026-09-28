import Foundation
@testable import UltraNav

@MainActor
struct RideEngineHarness {
    let location: FakeLocationProvider
    let workout: FakeWorkoutProvider
    let sensors: FakeSensorProvider
    let clock: TestClock
    let engine: RideEngine
    let recorder: RideSnapshotRecorder

    static func make(
        now: Date = Date(timeIntervalSince1970: 1_700_000_000),
        dependencyPolicy: RideDependencyPolicy = .outdoorCycling
    ) -> RideEngineHarness {
        let location = FakeLocationProvider()
        let workout = FakeWorkoutProvider()
        let sensors = FakeSensorProvider()
        let clock = TestClock(now: now)
        let engine = RideEngine(
            location: location,
            workout: workout,
            sensors: sensors,
            clock: clock,
            dependencyPolicy: dependencyPolicy
        )
        let recorder = RideSnapshotRecorder()
        recorder.startRecording(from: engine)

        return RideEngineHarness(
            location: location,
            workout: workout,
            sensors: sensors,
            clock: clock,
            engine: engine,
            recorder: recorder
        )
    }

    func authorizeAll() async {
        await location.setStubbedAuthorizationStatus(.authorized)
        await workout.setStubbedAuthorizationStatus(.authorized)
    }

    func prepareSuccessfully() async {
        await authorizeAll()
        await engine.send(.prepare)
    }

    func prepareAndStart() async {
        await prepareSuccessfully()
        await engine.send(.start)
    }
}
