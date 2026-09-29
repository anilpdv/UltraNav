# Phase 6 Baseline Assessment: Turn Detection & Cue Progression

## 1. Current State Assessment

- **Current Cue Type**: `NavigationCue` (`Domain/Navigation/NavigationCue.swift`) with `id: UUID`, `maneuver: NavigationManeuver`, `coordinate: Coordinate`, `routeDistanceMeters: Double`, `instruction: String?`.
- **Current Cue-Generation Owner**: `LegacyCueAdapter` (`Navigation/Cues/LegacyCueAdapter.swift`) which returns an empty list `[]`.
- **Current Cue Source**: None (stubbed).
- **Current Turn-Angle Calculation**: No turn calculation or bearing profile exists.
- **Current Next-Cue Logic**: Naive distance comparison checking `cues.first(where: { $0.routeDistanceMeters >= (userProgressDist - 25) })`.
- **Current Approach Threshold**: None (unimplemented in `LegacyCueAdapter`).
- **Current Immediate Threshold**: Hardcoded legacy 25m lookahead window.
- **Current Passed-Cue Behavior**: Blindly inserts all cue IDs where `cue.routeDistanceMeters < userProgressDist`.
- **Current Notification Behavior**: Handled via `NavigationNotificationCoordinator` when triggered, but `NavigationEngine` does not emit progressive `.approachingCue` or `.immediateCue` events from a dedicated `CueProgressor`.
- **Current Backtracking Behavior**: No backtracking hysteresis or replay suppression.
- **Current Route-Completion Dependency**: Independent (handled in `NavigationEngine`).
- **Known False-Turn Problems**: Micro-turns on curves, zig-zag GPX jitter, zero-distance duplicate points, segment boundary jumps.

---

## 2. Target Architecture (Phase 6)

```
Canonical Route
      ↓
RouteGeometryIndex
      ↓
RouteBearingProfile (smoothed bearings across distance windows, segment bounds)
      ↓
TurnCandidateDetector (window comparison, noise suppression, candidate extraction)
      ↓
TurnCandidateMerger (cluster grouping <= 25m, compound turns, net angle)
      ↓
ManeuverClassifier (signed turn angles: straight, slight, normal, sharp, uTurn)
      ↓
NavigationCueBuilder (deterministic UUID/ID, route distance, semantics)
      ↓
Ordered [NavigationCue]
      ↓ (Live RouteMatch progress)
CueProgressor (approach alert at 100m, immediate alert at 25m, passed threshold at 15m, backtracking suppression)
      ↓
CueProgress (active cue, distance, phase, passed IDs, notification events)
```

---

## 3. Git Baseline

- **Branch**: `feature/phase-6-turn-cues`
- **Base Commit**: `84b0fc9dbbd2b916e28fa85306eb587014df80c7`
- **Test Baseline**: 98 unit/integration tests passing (0 failures).
