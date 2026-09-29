import Foundation

public enum NavigationPhaseViewState: String, Codable, Equatable, Sendable {
    case inactive
    case loading
    case ready
    case navigating
    case offRoute
    case finished
    case failed
}

public enum ManeuverViewState: String, Codable, Equatable, Sendable {
    case straight
    case slightLeft
    case left
    case sharpLeft
    case slightRight
    case right
    case sharpRight
    case uTurn
    case arrive
    case unknown

    public var iconName: String {
        switch self {
        case .straight: return "arrow.up"
        case .slightLeft: return "arrow.up.left"
        case .left: return "arrow.turn.up.left"
        case .sharpLeft: return "arrow.uturn.backward"
        case .slightRight: return "arrow.up.right"
        case .right: return "arrow.turn.up.right"
        case .sharpRight: return "arrow.uturn.forward"
        case .uTurn: return "arrow.uturn.down"
        case .arrive: return "flag.checkered"
        case .unknown: return "arrow.triangle.turn.up.right.diamond"
        }
    }
}

public struct CueViewState: Equatable, Sendable {
    public let maneuver: ManeuverViewState
    public let instruction: String
    public let distance: MetricDisplayValue?
    public let accessibilityLabel: String

    public init(
        maneuver: ManeuverViewState,
        instruction: String,
        distance: MetricDisplayValue? = nil,
        accessibilityLabel: String
    ) {
        self.maneuver = maneuver
        self.instruction = instruction
        self.distance = distance
        self.accessibilityLabel = accessibilityLabel
    }
}

public enum NavigationBannerState: Equatable, Sendable {
    case calculating
    case possibleDeviation
    case offRoute(distance: MetricDisplayValue?)
    case rejoining
    case routeCompleted
    case error(message: String)
}

public enum NavigationPresentationAction: Equatable, Sendable {
    case appeared
    case startSelected
    case stopSelected
    case clearSelected
}
