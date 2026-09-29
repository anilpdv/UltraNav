import Foundation

/// MainActor coordinator managing climb analysis, active climb selection, real-time progress,
/// and live grade/VAM metrics.
@MainActor
final class ClimbEngine: ClimbEngineProviding {
    private let analysisService: ClimbAnalysisService
    private let selector: ActiveClimbSelecting
    private let progressCalculator: ClimbProgressCalculating
    private let snapshotBuilder: ClimbSnapshotBuilder

    private var state: ClimbEngineState = .unloaded
    private var currentRoute: Route?
    private var elevationProfile: ElevationProfile?
    private var climbs: [Climb] = []
    private var activeClimb: Climb?
    private var activeClimbProgress: ClimbProgress?
    private var upcomingClimb: Climb?
    private var distanceToUpcomingClimbMeters: Double?
    private var completedClimbIDs: Set<Climb.ID> = []
    private var lastApproachedClimbID: Climb.ID?

    private var totalElevationGainMeters: Double = 0
    private var currentElevationMeters: Double?
    private var currentGradePercent: Double = 0
    private var vamMetersPerHour: Double = 0
    private var failure: ClimbFailure?

    // Live elevation tracking buffer
    private var recentElevations: [(time: Date, alt: Double, dist: Double)] = []
    private var lastAltitude: Double?
    private var lastRouteDistanceMeters: Double = 0

    // Stream continuations
    private var snapshotContinuation: AsyncStream<ClimbSnapshot>.Continuation?
    private var notificationContinuation: AsyncStream<ClimbNotification>.Continuation?

    private(set) var currentSnapshot: ClimbSnapshot

    var snapshots: AsyncStream<ClimbSnapshot> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.snapshotContinuation = continuation
            continuation.yield(self.currentSnapshot)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.snapshotContinuation = nil
                }
            }
        }
    }

    var notifications: AsyncStream<ClimbNotification> {
        AsyncStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            self.notificationContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.notificationContinuation = nil
                }
            }
        }
    }

    init(
        analysisService: ClimbAnalysisService = ClimbAnalysisService(),
        selector: ActiveClimbSelecting = StandardActiveClimbSelector(),
        progressCalculator: ClimbProgressCalculating = StandardClimbProgressCalculator(),
        snapshotBuilder: ClimbSnapshotBuilder = ClimbSnapshotBuilder()
    ) {
        self.analysisService = analysisService
        self.selector = selector
        self.progressCalculator = progressCalculator
        self.snapshotBuilder = snapshotBuilder
        self.currentSnapshot = ClimbSnapshot.empty
    }

    func send(_ command: ClimbEngineCommand) async {
        switch command {
        case .loadRoute(let route):
            await handleLoadRoute(route)
        case .processNavigation(let navigationSnapshot):
            handleProcessNavigation(navigationSnapshot)
        case .processLocation(let locationSample):
            handleProcessLocation(locationSample)
        case .reset:
            handleReset()
        }
    }

    // MARK: - Command Handlers

    private func handleLoadRoute(_ route: Route) async {
        self.currentRoute = route
        self.state = .analyzing
        self.failure = nil
        self.climbs = []
        self.activeClimb = nil
        self.activeClimbProgress = nil
        self.upcomingClimb = nil
        self.distanceToUpcomingClimbMeters = nil
        self.completedClimbIDs = []
        self.lastApproachedClimbID = nil
        self.lastRouteDistanceMeters = 0
        publishSnapshot()

        do {
            let result = try await analysisService.analyze(route: route)
            self.elevationProfile = result.profile
            self.climbs = result.climbs

            // Initial selection at 0 distance
            let selection = selector.select(
                climbs: result.climbs,
                routeDistanceMeters: 0,
                previousActiveClimbID: nil,
                completedClimbIDs: [],
                approachThresholdMeters: 500.0
            )

            self.completedClimbIDs = selection.completedClimbIDs
            self.activeClimb = selection.activeClimb
            self.upcomingClimb = selection.upcomingClimb
            self.distanceToUpcomingClimbMeters = selection.distanceToUpcomingClimbMeters

            if let active = selection.activeClimb {
                self.activeClimbProgress = progressCalculator.calculateProgress(
                    for: active,
                    at: 0,
                    currentElevationMeters: currentElevationMeters,
                    quality: .reliable
                )
                self.state = .activeClimb
            } else if result.climbs.isEmpty {
                self.state = .ready
            } else {
                self.state = .ready
            }

            notificationContinuation?.yield(.routeAnalyzed(totalClimbs: result.climbs.count))
            publishSnapshot()
        } catch let climbFailure as ClimbFailure {
            self.state = .failed
            self.failure = climbFailure
            notificationContinuation?.yield(.analysisFailed(failure: climbFailure))
            publishSnapshot()
        } catch {
            let wrappedFailure = ClimbFailure.unexpected(error.localizedDescription)
            self.state = .failed
            self.failure = wrappedFailure
            notificationContinuation?.yield(.analysisFailed(failure: wrappedFailure))
            publishSnapshot()
        }
    }

    private func handleProcessNavigation(_ navigationSnapshot: NavigationSnapshot) {
        guard state != .unloaded && state != .failed else { return }

        let routeDistance = navigationSnapshot.distanceAlongRouteMeters
        self.lastRouteDistanceMeters = routeDistance

        let quality: ClimbProgressQuality
        switch navigationSnapshot.offRouteStatus {
        case .onRoute:
            quality = .reliable
        case .suspected, .rejoining:
            quality = .uncertain
        case .offRoute, .unknown:
            quality = .unavailable
        }

        let selection = selector.select(
            climbs: climbs,
            routeDistanceMeters: routeDistance,
            previousActiveClimbID: activeClimb?.id,
            completedClimbIDs: completedClimbIDs,
            approachThresholdMeters: 500.0
        )

        self.completedClimbIDs = selection.completedClimbIDs
        self.activeClimb = selection.activeClimb
        self.upcomingClimb = selection.upcomingClimb
        self.distanceToUpcomingClimbMeters = selection.distanceToUpcomingClimbMeters

        // Emit notifications
        if let approaching = selection.approachingClimb,
           let dist = selection.approachingDistanceMeters,
           approaching.id != lastApproachedClimbID {
            self.lastApproachedClimbID = approaching.id
            notificationContinuation?.yield(.climbApproaching(climb: approaching, distanceMeters: dist))
        }

        for skipped in selection.newlySkippedClimbs {
            notificationContinuation?.yield(.climbSkipped(climb: skipped))
        }

        if let completed = selection.newlyCompletedClimb {
            notificationContinuation?.yield(.climbCompleted(climb: completed))
        }

        if let started = selection.newlyStartedClimb {
            notificationContinuation?.yield(.climbStarted(climb: started))
        }

        // Update progress & state
        if let active = selection.activeClimb {
            self.activeClimbProgress = progressCalculator.calculateProgress(
                for: active,
                at: routeDistance,
                currentElevationMeters: currentElevationMeters,
                quality: quality
            )
            self.state = .activeClimb
        } else {
            self.activeClimbProgress = nil
            if !climbs.isEmpty && completedClimbIDs.count == climbs.count {
                if state != .completedAllClimbs {
                    notificationContinuation?.yield(.allClimbsCompleted)
                }
                self.state = .completedAllClimbs
            } else {
                self.state = .ready
            }
        }

        publishSnapshot()
    }

    private func handleProcessLocation(_ location: LocationSample) {
        guard let altitude = location.altitudeMeters else { return }
        self.currentElevationMeters = altitude

        if let last = lastAltitude {
            let dAlt = altitude - last
            if dAlt > 0.6 {
                totalElevationGainMeters += dAlt
            }
        }
        self.lastAltitude = altitude

        // Rolling Grade % and VAM calculation (15-second window)
        let now = location.timestamp
        recentElevations.append((time: now, alt: altitude, dist: lastRouteDistanceMeters))
        recentElevations.removeAll { now.timeIntervalSince($0.time) > 15 }

        if let first = recentElevations.first, recentElevations.count >= 3 {
            let deltaDist = lastRouteDistanceMeters - first.dist
            let deltaAlt = altitude - first.alt
            let deltaTime = now.timeIntervalSince(first.time)

            if deltaDist > 15 {
                let rawGrade = (deltaAlt / deltaDist) * 100.0
                self.currentGradePercent = (self.currentGradePercent * 0.7) + (rawGrade * 0.3)
            }

            if deltaTime > 5 && deltaAlt > 0 {
                self.vamMetersPerHour = (deltaAlt / deltaTime) * 3600.0
            }
        }

        // If active climb exists, update progress with fresh elevation
        if let active = activeClimb {
            self.activeClimbProgress = progressCalculator.calculateProgress(
                for: active,
                at: lastRouteDistanceMeters,
                currentElevationMeters: altitude,
                quality: activeClimbProgress?.quality ?? .reliable
            )
        }

        publishSnapshot()
    }

    private func handleReset() {
        self.state = .unloaded
        self.currentRoute = nil
        self.elevationProfile = nil
        self.climbs = []
        self.activeClimb = nil
        self.activeClimbProgress = nil
        self.upcomingClimb = nil
        self.distanceToUpcomingClimbMeters = nil
        self.completedClimbIDs = []
        self.lastApproachedClimbID = nil
        self.totalElevationGainMeters = 0
        self.currentElevationMeters = nil
        self.currentGradePercent = 0
        self.vamMetersPerHour = 0
        self.failure = nil
        self.recentElevations = []
        self.lastAltitude = nil
        self.lastRouteDistanceMeters = 0

        self.currentSnapshot = ClimbSnapshot.empty
        snapshotContinuation?.yield(self.currentSnapshot)
    }

    private func publishSnapshot() {
        let snapshot = snapshotBuilder.buildSnapshot(
            state: state,
            routeID: currentRoute?.id,
            climbs: climbs,
            activeClimb: activeClimb,
            activeClimbProgress: activeClimbProgress,
            upcomingClimb: upcomingClimb,
            distanceToUpcomingClimbMeters: distanceToUpcomingClimbMeters,
            completedClimbIDs: completedClimbIDs,
            totalElevationGainMeters: totalElevationGainMeters,
            currentElevationMeters: currentElevationMeters,
            currentGradePercent: currentGradePercent,
            vamMetersPerHour: vamMetersPerHour,
            failure: failure
        )
        self.currentSnapshot = snapshot
        snapshotContinuation?.yield(snapshot)
    }
}
