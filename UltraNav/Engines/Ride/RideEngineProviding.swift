import Foundation

@MainActor
protocol RideEngineProviding: AnyObject {
    var currentSnapshot: RideSnapshot { get }
    var snapshots: AsyncStream<RideSnapshot> { get }

    func send(_ command: RideEngineCommand) async
}
