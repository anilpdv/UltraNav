import Foundation

/// Conforming validator that ensures raw GPX parsed data has sufficient valid coordinates.
public final class ParsedRouteValidator: ParsedRouteValidating, Sendable {
    public init() {}

    public func validate(document: GPXParsedDocument, policy: ParsedRouteValidationPolicy) throws {
        // 1. Gather all points based on tracks vs fallback routes
        let trackPoints: [GPXParsedPoint] = document.tracks.flatMap { $0.segments.flatMap { $0.points } }
        let candidatePoints: [GPXParsedPoint]

        if !trackPoints.isEmpty {
            candidatePoints = trackPoints
        } else if policy.allowRoutePointsAsFallback && !document.routes.isEmpty {
            candidatePoints = document.routes.flatMap { $0.points }
        } else {
            throw ParsedRouteValidationFailure.noUsableCoordinates
        }

        // 2. Point count checks
        let count = candidatePoints.count
        if count < policy.minimumPointCount {
            throw ParsedRouteValidationFailure.insufficientPoints(found: count, minimumRequired: policy.minimumPointCount)
        }
        if count > policy.maximumPointCount {
            throw ParsedRouteValidationFailure.excessivePoints(found: count, maximumAllowed: policy.maximumPointCount)
        }

        // 3. Coordinate validity checks
        for pt in candidatePoints {
            let lat = pt.latitude
            let lon = pt.longitude

            if lat.isNaN || lat.isInfinite || lat < -90.0 || lat > 90.0 {
                throw ParsedRouteValidationFailure.invalidCoordinate(
                    latitude: lat,
                    longitude: lon,
                    reason: "Latitude \(lat) out of valid range [-90, 90]"
                )
            }

            if lon.isNaN || lon.isInfinite || lon < -180.0 || lon > 180.0 {
                throw ParsedRouteValidationFailure.invalidCoordinate(
                    latitude: lat,
                    longitude: lon,
                    reason: "Longitude \(lon) out of valid range [-180, 180]"
                )
            }
        }
    }
}
