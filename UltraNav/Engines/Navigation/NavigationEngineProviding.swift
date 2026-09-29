import Foundation

@MainActor
protocol NavigationEngineProviding: AnyObject {
    var currentSnapshot: NavigationSnapshot { get }
    var snapshots: AsyncStream<NavigationSnapshot> { get }
    var notifications: AsyncStream<NavigationNotification> { get }

    func send(_ command: NavigationEngineCommand) async
    func consume(location: LocationSample)
}
