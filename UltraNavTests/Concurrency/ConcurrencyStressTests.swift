import Foundation
import Testing
@testable import UltraNav

@Suite("ConcurrencyStress Tests")
struct ConcurrencyStressTests {
    @Test("Concurrent producers safely send events to channel")
    func testConcurrentProducers() async {
        let channel = AsyncEventChannel<Int>()
        let stream = channel.makeStream()

        let iterations = 100
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    for j in 0..<iterations {
                        channel.send((i * iterations) + j)
                    }
                }
            }
        }
        channel.finish()

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count == 10 * iterations)
    }

    @Test("LockedValue handles heavy concurrent read-write contention")
    func testLockedValueConcurrentContention() async {
        let locked = LockedValue(0)
        let iterations = 500

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    for _ in 0..<iterations {
                        locked.withLock { $0 += 1 }
                    }
                }
            }
        }

        #expect(locked.get() == 10 * iterations)
    }
}
