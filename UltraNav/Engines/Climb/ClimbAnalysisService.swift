import Foundation

/// Background actor responsible for performing heavy elevation profile construction,
/// climb detection, and climb classification off the main UI actor.
actor ClimbAnalysisService {
    private let profileBuilder: ElevationProfileBuilding
    private let detector: ClimbDetecting
    private let assembler: ClimbAssembler

    init(
        profileBuilder: ElevationProfileBuilding = LegacyElevationProfileBuilder(),
        detector: ClimbDetecting = LegacyClimbDetector(),
        assembler: ClimbAssembler = ClimbAssembler()
    ) {
        self.profileBuilder = profileBuilder
        self.detector = detector
        self.assembler = assembler
    }

    func analyze(route: Route) throws -> (profile: ElevationProfile, climbs: [Climb]) {
        let profile: ElevationProfile
        do {
            profile = try profileBuilder.buildProfile(for: route)
        } catch let failure as ClimbFailure {
            throw failure
        } catch {
            throw ClimbFailure.profileConstructionFailed(error.localizedDescription)
        }

        let candidates: [ClimbCandidate]
        do {
            candidates = try detector.detectClimbs(in: profile)
        } catch let failure as ClimbFailure {
            throw failure
        } catch {
            throw ClimbFailure.climbDetectionFailed(error.localizedDescription)
        }

        let climbs = assembler.assemble(candidates: candidates, routeID: route.id)
        return (profile, climbs)
    }
}
