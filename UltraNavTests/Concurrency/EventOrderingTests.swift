import Foundation
import Testing
@testable import UltraNav

@Suite("EventOrdering Tests")
struct EventOrderingTests {
    @Test("Events emitted in sequence preserve strict FIFO ordering")
    func testEventsPreserveFIFOOrdering() async {
        let channel = AsyncEventChannel<Int>()
        let stream = channel.makeStream()

        let total = 50
        for i in 0..<total {
            channel.send(i)
        }
        channel.finish()

        var received: [Int] = []
        for await item in stream {
            received.append(item)
        }

        #expect(received == Array(0..<total))
    }
}
