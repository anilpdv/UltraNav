import Foundation

@MainActor
protocol RideLocationConsuming: AnyObject {
    func handle(locationEvent: LocationServiceEvent)
}
