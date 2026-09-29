import Foundation
import Testing
@testable import UltraNav

@Suite("StreamCancellation Tests")
struct StreamCancellationTests {
    @Test("Cancelling consumer task stops stream consumption cleanly")
    func testCancellingConsumerTaskStopsStream() async {
        let channel = AsyncEventChannel<Int>()
        let stream = channel.makeStream()
        let receivedCount = LockedValue(0)

        let consumerTask = Task {
            for await _ in stream {
                receivedCount.withLock { $0 += 1 }
            }
        }

        channel.send(1)
        channel.send(2)
        try? await Task.sleep(nanoseconds: 20_000_000)

        consumerTask.cancel()
        channel.send(3)
        channel.finish()
        try? await Task.sleep(nanoseconds: 20_000_000)

        #expect(receivedCount.get() == 2)
    }

    @Test("CancellationToken triggers registered callbacks on cancel")
    func testCancellationTokenTriggersCallbacks() {
        let token = CancellationToken()
        let called = LockedValue(false)

        token.onCancel {
            called.set(true)
        }

        #expect(!token.isCancelled)
        token.cancel()
        #expect(token.isCancelled)
        #expect(called.get())
    }
}
