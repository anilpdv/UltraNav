import Foundation

public enum ClimbPhaseViewState: String, Codable, Equatable, Sendable {
    case unavailable
    case analyzing
    case noClimbs
    case upcoming
    case approaching
    case active
    case completed
    case failed
}

public enum GradientBandViewState: String, Codable, Equatable, Sendable {
    case descent
    case easy
    case moderate
    case hard
    case severe

    public var badgeColorHex: String {
        switch self {
        case .descent: return "#00FFFF" // Cyan
        case .easy: return "#00FF00"    // Green
        case .moderate: return "#FFFF00"// Yellow
        case .hard: return "#FF8000"    // Orange
        case .severe: return "#FF0000"  // Red
        }
    }
}

public struct ClimbProfilePointViewState: Equatable, Sendable {
    public let normalizedDistance: Double
    public let normalizedElevation: Double
    public let gradientBand: GradientBandViewState

    public init(normalizedDistance: Double, normalizedElevation: Double, gradientBand: GradientBandViewState) {
        self.normalizedDistance = normalizedDistance
        self.normalizedElevation = normalizedElevation
        self.gradientBand = gradientBand
    }
}

public struct ClimbProfileViewState: Equatable, Sendable {
    public let points: [ClimbProfilePointViewState]
    public let currentProgress: Double
    public let summitLabel: String
    public let accessibilitySummary: String

    public init(
        points: [ClimbProfilePointViewState],
        currentProgress: Double = 0.0,
        summitLabel: String = "",
        accessibilitySummary: String = ""
    ) {
        self.points = points
        self.currentProgress = currentProgress
        self.summitLabel = summitLabel
        self.accessibilitySummary = accessibilitySummary
    }
}

public struct ClimbViewState: Equatable, Sendable {
    public let phase: ClimbPhaseViewState
    public let categoryText: String?
    public let distanceRemaining: MetricDisplayValue?
    public let elevationRemaining: MetricDisplayValue?
    public let currentGradient: MetricDisplayValue?
    public let progress: Double
    public let profile: ClimbProfileViewState?
    public let message: String?

    public init(
        phase: ClimbPhaseViewState,
        categoryText: String? = nil,
        distanceRemaining: MetricDisplayValue? = nil,
        elevationRemaining: MetricDisplayValue? = nil,
        currentGradient: MetricDisplayValue? = nil,
        progress: Double = 0.0,
        profile: ClimbProfileViewState? = nil,
        message: String? = nil
    ) {
        self.phase = phase
        self.categoryText = categoryText
        self.distanceRemaining = distanceRemaining
        self.elevationRemaining = elevationRemaining
        self.currentGradient = currentGradient
        self.progress = progress
        self.profile = profile
        self.message = message
    }

    public static let initial = ClimbViewState(phase: .unavailable)
}

public enum ClimbPresentationAction: Equatable, Sendable {
    case appeared
    case retrySelected
}
