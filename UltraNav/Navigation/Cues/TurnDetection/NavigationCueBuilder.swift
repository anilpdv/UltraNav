import Foundation
import CryptoKit

/// Generates deterministic, ordered navigation cues from canonical route geometry.
struct NavigationCueBuilder: NavigationCueProviding, Sendable {
    let detector: TurnCandidateDetector
    let merger: TurnCandidateMerger

    init(
        detector: TurnCandidateDetector = TurnCandidateDetector(),
        merger: TurnCandidateMerger = TurnCandidateMerger()
    ) {
        self.detector = detector
        self.merger = merger
    }

    /// Synthesizes a deterministic ordered cue list for a route.
    func cues(for route: Route) throws -> [NavigationCue] {
        let profile = RouteBearingProfile(route: route)
        let rawCandidates = detector.detectCandidates(profile: profile)
        let mergedCandidates = merger.merge(candidates: rawCandidates)

        var cues: [NavigationCue] = []

        for (index, candidate) in mergedCandidates.enumerated() {
            let cueID = deterministicUUID(
                routeIDString: route.id.rawValue,
                index: index,
                distanceMeters: candidate.distanceAlongRouteMeters,
                maneuver: candidate.maneuver.rawValue
            )
            let instruction = ManeuverClassifier.defaultInstruction(for: candidate.maneuver)

            cues.append(
                NavigationCue(
                    id: cueID,
                    maneuver: candidate.maneuver,
                    coordinate: candidate.coordinate,
                    routeDistanceMeters: candidate.distanceAlongRouteMeters,
                    instruction: instruction
                )
            )
        }

        // Add destination arrival cue if route is substantial
        if profile.totalDistanceMeters >= 50.0, let finalCoord = profile.coordinate(at: profile.totalDistanceMeters) {
            let arriveID = deterministicUUID(
                routeIDString: route.id.rawValue,
                index: cues.count,
                distanceMeters: profile.totalDistanceMeters,
                maneuver: NavigationManeuver.arrive.rawValue
            )
            cues.append(
                NavigationCue(
                    id: arriveID,
                    maneuver: .arrive,
                    coordinate: finalCoord,
                    routeDistanceMeters: profile.totalDistanceMeters,
                    instruction: ManeuverClassifier.defaultInstruction(for: .arrive)
                )
            )
        }

        return cues.sorted(by: { $0.routeDistanceMeters < $1.routeDistanceMeters })
    }

    private func deterministicUUID(
        routeIDString: String,
        index: Int,
        distanceMeters: Double,
        maneuver: String
    ) -> UUID {
        let key = "\(routeIDString):\(index):\(Int(distanceMeters.rounded())):$\(maneuver)"
        let digest = Insecure.MD5.hash(data: Data(key.utf8))
        var bytes = Array(digest)
        // Set UUID version 4 and variant RFC 4122
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let uuidTuple: uuid_t = (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        )
        return UUID(uuid: uuidTuple)
    }
}
