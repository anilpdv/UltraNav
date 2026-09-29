import Foundation

/// Encapsulates a distinct off-route deviation incident from initial suspicion through resolution.
struct OffRouteEpisode: Identifiable, Equatable, Sendable {
    struct ID: RawRepresentable, Hashable, Sendable {
        let rawValue: UUID

        init(rawValue: UUID = UUID()) {
            self.rawValue = rawValue
        }
    }

    let id: ID
    let suspectedAt: Date
    var confirmedAt: Date?
    var rejoinStartedAt: Date?
    var resolvedAt: Date?
    var maximumObservedCrossTrackMeters: Double?
    var unavailableMatchCount: Int
    var ambiguousMatchCount: Int

    init(
        id: ID = ID(),
        suspectedAt: Date = Date(),
        confirmedAt: Date? = nil,
        rejoinStartedAt: Date? = nil,
        resolvedAt: Date? = nil,
        maximumObservedCrossTrackMeters: Double? = nil,
        unavailableMatchCount: Int = 0,
        ambiguousMatchCount: Int = 0
    ) {
        self.id = id
        self.suspectedAt = suspectedAt
        self.confirmedAt = confirmedAt
        self.rejoinStartedAt = rejoinStartedAt
        self.resolvedAt = resolvedAt
        self.maximumObservedCrossTrackMeters = maximumObservedCrossTrackMeters
        self.unavailableMatchCount = unavailableMatchCount
        self.ambiguousMatchCount = ambiguousMatchCount
    }
}
