import Foundation

/// Legacy implementation of ElevationProfileBuilding that extracts valid elevation points from Route.
struct LegacyElevationProfileBuilder: ElevationProfileBuilding {
    init() {}

    func buildProfile(for route: Route) throws -> ElevationProfile {
        guard !route.points.isEmpty else {
            throw ClimbFailure.noElevationData
        }

        var profilePoints: [ElevationProfilePoint] = []
        profilePoints.reserveCapacity(route.points.count)

        for (index, pt) in route.points.enumerated() {
            guard let ele = pt.elevationMeters else { continue }
            profilePoints.append(ElevationProfilePoint(
                distanceMeters: pt.cumulativeDistanceMeters,
                elevationMeters: ele,
                originalIndex: index
            ))
        }

        guard !profilePoints.isEmpty else {
            throw ClimbFailure.noElevationData
        }

        guard profilePoints.count >= 2 else {
            throw ClimbFailure.insufficientElevationData
        }

        var totalAscent: Double = 0
        var totalDescent: Double = 0
        var minEle: Double = profilePoints[0].elevationMeters
        var maxEle: Double = profilePoints[0].elevationMeters

        for i in 1..<profilePoints.count {
            let prev = profilePoints[i - 1].elevationMeters
            let curr = profilePoints[i].elevationMeters
            let delta = curr - prev

            if delta > 0 {
                totalAscent += delta
            } else if delta < 0 {
                totalDescent += abs(delta)
            }

            if curr < minEle { minEle = curr }
            if curr > maxEle { maxEle = curr }
        }

        return ElevationProfile(
            routeID: route.id,
            points: profilePoints,
            totalAscentMeters: totalAscent,
            totalDescentMeters: totalDescent,
            minElevationMeters: minEle,
            maxElevationMeters: maxEle
        )
    }
}
