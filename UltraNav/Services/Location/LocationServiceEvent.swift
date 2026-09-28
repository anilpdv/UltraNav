import Foundation

enum LocationServiceEvent: Equatable, Sendable {
    case authorizationChanged(
        LocationAuthorizationStatus
    )

    case updateStarted

    case locationReceived(
        LocationSample
    )

    case updateStopped

    case failed(
        LocationServiceFailure
    )
}
