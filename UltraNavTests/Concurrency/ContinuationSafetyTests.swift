import Foundation
import Testing
@testable import UltraNav

@Suite("ContinuationSafety Tests")
struct ContinuationSafetyTests {
    @Test("EventStreamOwner yielding after finish is safely ignored")
    func testYieldAfterFinishIsIgnored() {
        let owner = EventStreamOwner<Int>()
        owner.yield(1)
        owner.finish()
        #expect(owner.isFinished)

        let result = owner.yield(2)
        #expect(result == nil)
    }

    @Test("Channel sending after finish does not crash or emit")
    func testChannelSendAfterFinish() {
        let channel = AsyncEventChannel<String>()
        channel.send("first")
        channel.finish()
        #expect(channel.isFinished)

        channel.send("second")
        #expect(channel.isFinished)
    }
}
