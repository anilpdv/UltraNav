import Foundation

/// Standard implementation of GPXContentSelecting executing deterministic selection rules.
public struct StandardGPXContentSelector: GPXContentSelecting, Sendable {
    public init() {}

    public func extractCandidates(from document: GPXParsedDocument) -> [GPXContentCandidate] {
        var candidates: [GPXContentCandidate] = []

        for (index, track) in document.tracks.enumerated() {
            let pts = track.segments.reduce(0) { $0 + $1.points.count }
            candidates.append(GPXContentCandidate(
                id: "track-\(index)",
                kind: .track,
                name: track.name,
                pointCount: pts,
                segmentCount: track.segments.count
            ))
        }

        for (index, route) in document.routes.enumerated() {
            candidates.append(GPXContentCandidate(
                id: "route-\(index)",
                kind: .route,
                name: route.name,
                pointCount: route.points.count,
                segmentCount: 1
            ))
        }

        return candidates
    }

    public func selectContent(
        from document: GPXParsedDocument,
        policy: GPXContentSelectionPolicy
    ) throws -> GPXContentSelection {
        var warnings: [String] = []

        let nonEmptyTracks = document.tracks.filter { track in
            track.segments.contains { !$0.points.isEmpty }
        }
        let nonEmptyRoutes = document.routes.filter { !$0.points.isEmpty }

        if nonEmptyTracks.isEmpty && nonEmptyRoutes.isEmpty {
            if !document.waypoints.isEmpty {
                return GPXContentSelection(
                    segments: [],
                    waypoints: document.waypoints,
                    selectedName: document.metadata.name,
                    selectedDescription: document.metadata.description,
                    sourceKind: .waypointsOnly,
                    warnings: ["Document contains only waypoints; no track or route geometry found."]
                )
            }
            throw GPXParserFailure.noSupportedContent
        }

        switch policy {
        case .firstTrack:
            if let first = nonEmptyTracks.first {
                return GPXContentSelection(
                    segments: first.segments,
                    waypoints: document.waypoints,
                    selectedName: first.name ?? document.metadata.name,
                    selectedDescription: first.description ?? document.metadata.description,
                    sourceKind: .track
                )
            }
            throw GPXParserFailure.noSupportedContent

        case .longestTrack:
            if let longest = nonEmptyTracks.max(by: { a, b in
                a.segments.reduce(0) { $0 + $1.points.count } < b.segments.reduce(0) { $0 + $1.points.count }
            }) {
                if nonEmptyTracks.count > 1 {
                    warnings.append("Selected longest track out of \(nonEmptyTracks.count) tracks.")
                }
                return GPXContentSelection(
                    segments: longest.segments,
                    waypoints: document.waypoints,
                    selectedName: longest.name ?? document.metadata.name,
                    selectedDescription: longest.description ?? document.metadata.description,
                    sourceKind: .track,
                    warnings: warnings
                )
            }
            throw GPXParserFailure.noSupportedContent

        case .mergeAllTracks:
            if !nonEmptyTracks.isEmpty {
                let allSegments = nonEmptyTracks.flatMap { $0.segments }
                if nonEmptyTracks.count > 1 {
                    warnings.append("Merged \(nonEmptyTracks.count) tracks with \(allSegments.count) segments.")
                }
                return GPXContentSelection(
                    segments: allSegments,
                    waypoints: document.waypoints,
                    selectedName: nonEmptyTracks.first?.name ?? document.metadata.name,
                    selectedDescription: nonEmptyTracks.first?.description ?? document.metadata.description,
                    sourceKind: .mergedTracks,
                    warnings: warnings
                )
            }
            throw GPXParserFailure.noSupportedContent

        case .firstRoute:
            if let first = nonEmptyRoutes.first {
                let seg = GPXParsedSegment(points: first.points)
                return GPXContentSelection(
                    segments: [seg],
                    waypoints: document.waypoints,
                    selectedName: first.name ?? document.metadata.name,
                    selectedDescription: first.description ?? document.metadata.description,
                    sourceKind: .route
                )
            }
            throw GPXParserFailure.noSupportedContent

        case .longestRoute:
            if let longest = nonEmptyRoutes.max(by: { $0.points.count < $1.points.count }) {
                if nonEmptyRoutes.count > 1 {
                    warnings.append("Selected longest route out of \(nonEmptyRoutes.count) routes.")
                }
                let seg = GPXParsedSegment(points: longest.points)
                return GPXContentSelection(
                    segments: [seg],
                    waypoints: document.waypoints,
                    selectedName: longest.name ?? document.metadata.name,
                    selectedDescription: longest.description ?? document.metadata.description,
                    sourceKind: .route,
                    warnings: warnings
                )
            }
            throw GPXParserFailure.noSupportedContent

        case .preferTracks, .requireExplicitSelection:
            if !nonEmptyTracks.isEmpty {
                if nonEmptyTracks.count > 1 {
                    warnings.append("Multiple tracks found (\(nonEmptyTracks.count)). Deterministically selected longest track.")
                }
                let bestTrack = nonEmptyTracks.max(by: { a, b in
                    a.segments.reduce(0) { $0 + $1.points.count } < b.segments.reduce(0) { $0 + $1.points.count }
                })!
                return GPXContentSelection(
                    segments: bestTrack.segments,
                    waypoints: document.waypoints,
                    selectedName: bestTrack.name ?? document.metadata.name,
                    selectedDescription: bestTrack.description ?? document.metadata.description,
                    sourceKind: .track,
                    warnings: warnings
                )
            } else if let bestRoute = nonEmptyRoutes.max(by: { $0.points.count < $1.points.count }) {
                if nonEmptyRoutes.count > 1 {
                    warnings.append("Multiple routes found (\(nonEmptyRoutes.count)). Selected longest route.")
                }
                let seg = GPXParsedSegment(points: bestRoute.points)
                return GPXContentSelection(
                    segments: [seg],
                    waypoints: document.waypoints,
                    selectedName: bestRoute.name ?? document.metadata.name,
                    selectedDescription: bestRoute.description ?? document.metadata.description,
                    sourceKind: .route,
                    warnings: warnings
                )
            }
            throw GPXParserFailure.noSupportedContent

        case .preferRoutes:
            if let bestRoute = nonEmptyRoutes.max(by: { $0.points.count < $1.points.count }) {
                if nonEmptyRoutes.count > 1 {
                    warnings.append("Multiple routes found (\(nonEmptyRoutes.count)). Selected longest route.")
                }
                let seg = GPXParsedSegment(points: bestRoute.points)
                return GPXContentSelection(
                    segments: [seg],
                    waypoints: document.waypoints,
                    selectedName: bestRoute.name ?? document.metadata.name,
                    selectedDescription: bestRoute.description ?? document.metadata.description,
                    sourceKind: .route,
                    warnings: warnings
                )
            } else if let bestTrack = nonEmptyTracks.max(by: { a, b in
                a.segments.reduce(0) { $0 + $1.points.count } < b.segments.reduce(0) { $0 + $1.points.count }
            }) {
                if nonEmptyTracks.count > 1 {
                    warnings.append("Multiple tracks found (\(nonEmptyTracks.count)). Selected longest track.")
                }
                return GPXContentSelection(
                    segments: bestTrack.segments,
                    waypoints: document.waypoints,
                    selectedName: bestTrack.name ?? document.metadata.name,
                    selectedDescription: bestTrack.description ?? document.metadata.description,
                    sourceKind: .track,
                    warnings: warnings
                )
            }
            throw GPXParserFailure.noSupportedContent
        }
    }
}
