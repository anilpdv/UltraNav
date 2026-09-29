import Foundation

/// Legacy candidate detector wrapping GPXParser's climb thresholding algorithm.
struct LegacyClimbDetector: ClimbDetecting {
    init() {}

    func detectClimbs(in profile: ElevationProfile) throws -> [ClimbCandidate] {
        let points = profile.points
        guard points.count >= 3 else { return [] }

        var candidates: [ClimbCandidate] = []
        var inClimb = false
        var climbStartIdx = 0
        var climbGain = 0.0

        for i in 1..<points.count {
            let prev = points[i - 1]
            let curr = points[i]

            let dDist = curr.distanceMeters - prev.distanceMeters
            let dEle = curr.elevationMeters - prev.elevationMeters

            if dDist > 0 {
                let gradePercent = (dEle / dDist) * 100.0
                if gradePercent >= 3.0 {
                    if !inClimb {
                        inClimb = true
                        climbStartIdx = i - 1
                        climbGain = 0
                    }
                    if dEle > 0 { climbGain += dEle }
                } else if inClimb && (gradePercent < 0.5 || i == points.count - 1) {
                    let startPt = points[climbStartIdx]
                    let endPt = points[i]
                    let climbDist = endPt.distanceMeters - startPt.distanceMeters
                    let netGain = endPt.elevationMeters - startPt.elevationMeters

                    let score = climbDist * (netGain / max(1, climbDist) * 100.0)
                    if climbDist >= 400 && netGain >= 20 && score >= 1200 {
                        var maxGradeRatio: Double = 0
                        var slices: [ClimbGradientSlice] = []

                        for s in climbStartIdx..<i {
                            let s1 = points[s]
                            let s2 = points[s + 1]
                            let sDist = s2.distanceMeters - s1.distanceMeters
                            let sEle = s2.elevationMeters - s1.elevationMeters
                            if sDist > 0 {
                                let ratio = sEle / sDist
                                if ratio > maxGradeRatio { maxGradeRatio = ratio }
                                slices.append(ClimbGradientSlice(
                                    startDistanceMeters: s1.distanceMeters,
                                    endDistanceMeters: s2.distanceMeters,
                                    startElevationMeters: s1.elevationMeters,
                                    endElevationMeters: s2.elevationMeters,
                                    gradientRatio: ratio
                                ))
                            }
                        }

                        let avgGradeRatio = climbDist > 0 ? netGain / climbDist : 0

                        candidates.append(ClimbCandidate(
                            startIndex: climbStartIdx,
                            endIndex: i,
                            startDistanceMeters: startPt.distanceMeters,
                            endDistanceMeters: endPt.distanceMeters,
                            startElevationMeters: startPt.elevationMeters,
                            endElevationMeters: endPt.elevationMeters,
                            summitElevationMeters: endPt.elevationMeters,
                            netElevationGainMeters: netGain,
                            totalElevationGainMeters: climbGain,
                            averageGradientRatio: avgGradeRatio,
                            maximumGradientRatio: maxGradeRatio,
                            slices: slices
                        ))
                    }
                    inClimb = false
                }
            }
        }

        // Handle case where route ends while still climbing
        if inClimb {
            let startPt = points[climbStartIdx]
            let endPt = points[points.count - 1]
            let climbDist = endPt.distanceMeters - startPt.distanceMeters
            let netGain = endPt.elevationMeters - startPt.elevationMeters

            let score = climbDist * (netGain / max(1, climbDist) * 100.0)
            if climbDist >= 400 && netGain >= 20 && score >= 1200 {
                var maxGradeRatio: Double = 0
                var slices: [ClimbGradientSlice] = []

                for s in climbStartIdx..<(points.count - 1) {
                    let s1 = points[s]
                    let s2 = points[s + 1]
                    let sDist = s2.distanceMeters - s1.distanceMeters
                    let sEle = s2.elevationMeters - s1.elevationMeters
                    if sDist > 0 {
                        let ratio = sEle / sDist
                        if ratio > maxGradeRatio { maxGradeRatio = ratio }
                        slices.append(ClimbGradientSlice(
                            startDistanceMeters: s1.distanceMeters,
                            endDistanceMeters: s2.distanceMeters,
                            startElevationMeters: s1.elevationMeters,
                            endElevationMeters: s2.elevationMeters,
                            gradientRatio: ratio
                        ))
                    }
                }

                let avgGradeRatio = climbDist > 0 ? netGain / climbDist : 0

                candidates.append(ClimbCandidate(
                    startIndex: climbStartIdx,
                    endIndex: points.count - 1,
                    startDistanceMeters: startPt.distanceMeters,
                    endDistanceMeters: endPt.distanceMeters,
                    startElevationMeters: startPt.elevationMeters,
                    endElevationMeters: endPt.elevationMeters,
                    summitElevationMeters: endPt.elevationMeters,
                    netElevationGainMeters: netGain,
                    totalElevationGainMeters: climbGain,
                    averageGradientRatio: avgGradeRatio,
                    maximumGradientRatio: maxGradeRatio,
                    slices: slices
                ))
            }
        }

        return candidates
    }
}
