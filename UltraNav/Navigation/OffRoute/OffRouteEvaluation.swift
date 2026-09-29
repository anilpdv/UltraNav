import Foundation

struct OffRouteEvaluation: Equatable, Sendable {
    let status: OffRouteStatus
    let shouldNotify: Bool

    init(
        status: OffRouteStatus,
        shouldNotify: Bool
    ) {
        self.status = status
        self.shouldNotify = shouldNotify
    }
}
