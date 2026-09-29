import Foundation
import Testing
@testable import UltraNav

@Suite("AsyncEventChannel Concurrency Tests")
struct AsyncEventChannelTests {
    @Test("Single subscriber receives emitted events in order")
    func testSingleSubscriberReceivesEventsInOrder() async {
        let channel = AsyncEventChannel<Int>()
        let stream = channel.makeStream()

        channel.send(1)
        channel.send(2)
        channel.send(3)
        channel.finish()

        var received: [Int] = []
        for await value in stream {
            received.append(value)
        }

        #expect(received == [1, 2, 3])
        #expect(channel.isFinished)
    }

    @Test("Multiple subscribers receive broadcast events")
    func testMultipleSubscribersReceiveEvents() async {
        let channel = AsyncEventChannel<String>()
        let stream1 = channel.makeStream()
        let stream2 = channel.makeStream()

        #expect(channel.subscriberCount == 2)

        channel.send("alpha")
        channel.send("beta")
        channel.finish()

        var received1: [String] = []
        for await value in stream1 {
            received1.append(value)
        }

        var received2: [String] = []
        for await value in stream2 {
            received2.append(value)
        }

        #expect(received1 == ["alpha", "beta"])
        #expect(received2 == ["alpha", "beta"])
    }

    @Test("Subscriber terminating removes itself from active subscriber count")
    func testSubscriberTerminationRemovesFromCount() async {
        let channel = AsyncEventChannel<Int>()
        var stream: AsyncStream<Int>? = channel.makeStream()
        _ = stream
        #expect(channel.subscriberCount == 1)

        stream = nil
        // Allow termination callback to execute
        try? await Task.sleep(nanoseconds: 10_000_000)

        #expect(channel.subscriberCount == 0)
    }
}
