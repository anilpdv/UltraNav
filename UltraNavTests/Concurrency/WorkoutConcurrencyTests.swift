import Foundation
import Testing
@testable import UltraNav

@Suite("WorkoutConcurrency Tests")
struct WorkoutConcurrencyTests {
    @Test("Workout mock stream handles concurrent state transitions")
    func testWorkoutMockEvents() async {
        let fake = FakeWorkoutProvider()
        let received = LockedValue<[WorkoutServiceEvent]>([])

        let task = Task {
            for await event in fake.events {
                received.withLock { $0.append(event) }
            }
        }

        fake.send(.stateChanged(.prepared))
        fake.send(.stateChanged(.running))
        fake.send(.heartRateReceived(beatsPerMinute: 155, timestamp: Date()))

        try? await Task.sleep(nanoseconds: 30_000_000)
        fake.finishEvents()
        task.cancel()

        #expect(received.get().count >= 2)
    }
}
