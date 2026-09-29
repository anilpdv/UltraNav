import Foundation

public enum MetricTileEmphasis: String, Codable, Equatable, Sendable {
    case normal
    case primary
    case warning
}

public struct MetricZoneViewState: Equatable, Sendable {
    public let zoneNumber: Int
    public let zoneName: String
    public let progress: Double

    public init(zoneNumber: Int, zoneName: String, progress: Double) {
        self.zoneNumber = zoneNumber
        self.zoneName = zoneName
        self.progress = progress
    }
}

public struct MetricTileState: Identifiable, Equatable, Sendable {
    public enum MetricID: String, Hashable, Sendable {
        case speed
        case averageSpeed
        case distance
        case heartRate
        case cadence
        case power
        case elapsedTime
        case movingTime
        case altitude
    }

    public let id: MetricID
    public let title: String
    public let value: MetricDisplayValue
    public let emphasis: MetricTileEmphasis
    public let zone: MetricZoneViewState?

    public init(
        id: MetricID,
        title: String,
        value: MetricDisplayValue,
        emphasis: MetricTileEmphasis = .normal,
        zone: MetricZoneViewState? = nil
    ) {
        self.id = id
        self.title = title
        self.value = value
        self.emphasis = emphasis
        self.zone = zone
    }
}

public struct MetricsViewState: Equatable, Sendable {
    public let tiles: [MetricTileState]
    public let isRecording: Bool
    public let isPaused: Bool
    public let warning: BannerViewState?

    public init(
        tiles: [MetricTileState],
        isRecording: Bool = false,
        isPaused: Bool = false,
        warning: BannerViewState? = nil
    ) {
        self.tiles = tiles
        self.isRecording = isRecording
        self.isPaused = isPaused
        self.warning = warning
    }

    public static let initial = MetricsViewState(
        tiles: [],
        isRecording: false,
        isPaused: false
    )

    public func tile(for id: MetricTileState.MetricID) -> MetricTileState? {
        tiles.first(where: { $0.id == id })
    }
}

public enum MetricsPresentationAction: Equatable, Sendable {
    case appeared
    case tileSelected(MetricTileState.MetricID)
}
