import Foundation

/// Policy controlling how track and route content is selected from a GPX document.
public enum GPXContentSelectionPolicy: Equatable, Sendable {
    case firstTrack
    case longestTrack
    case mergeAllTracks
    case firstRoute
    case longestRoute
    case preferTracks
    case preferRoutes
    case requireExplicitSelection
}
