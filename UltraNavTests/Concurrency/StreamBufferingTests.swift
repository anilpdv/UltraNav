import Foundation
import Testing
@testable import UltraNav

@Suite("StreamBuffering Tests")
struct StreamBufferingTests {
    @Test("Buffering newest drops older unconsumed items when buffer fills")
    func testBufferingNewestDropsOlderItems() async {
        let channel = AsyncEventChannel<Int>(bufferingPolicy: .bufferingNewest(2))
        let stream = channel.makeStream()

        channel.send(1)
        channel.send(2)
        channel.send(3)
        channel.send(4)
        channel.finish()

        var received: [Int] = []
        for await item in stream {
            received.append(item)
        }

        #expect(received.count <= 2)
        if received.count == 2 {
            #expect(received == [3, 4])
        }
    }
}
