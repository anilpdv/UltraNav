import Foundation
import Testing
@testable import UltraNav

@Suite("TaskRetention Tests")
struct TaskRetentionTests {
    @Test("Deallocating TaskRegistry cancels all stored tasks")
    func testTaskRegistryDeallocCancelsTasks() async {
        let taskCompleted = LockedValue(false)

        var registry: TaskRegistry? = TaskRegistry()
        let task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            taskCompleted.set(true)
        }
        registry?.store(task, forKey: "background")
        registry = nil

        try? await Task.sleep(nanoseconds: 50_000_000)
        #expect(taskCompleted.get())
    }
}
