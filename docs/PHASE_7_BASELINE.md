# Phase 7 Baseline Assessment: Off-Route Detection and Rejoin

## 1. Current State Assessment

- **Current Off-Route Threshold**: Hardcoded fixed hysteresis in `LegacyOffRouteEvaluator` (35m off-route, 25m recovery, 0 GPS accuracy dampening, 0 duration persistence).
- **Current Off-Route Evaluator**: `LegacyOffRouteEvaluator` (`Navigation/OffRoute/LegacyOffRouteEvaluator.swift`), which evaluates only single-point cross-track distance.
- **Current Suspected-Deviation Behavior**: Instantly flags `.suspected` if crossTrack $> 25\text{m}$ on a single GPS tick.
- **Current Notification Behavior**: Emits `.offRoute`, `.possibleDeviation`, and `.routeRejoined` upon status change.
- **Current Rejoin Behavior**: Simple cross-track distance check $\le 25\text{m}$ with 0 heading or forward progress check.
- **Current Route-Progress Behavior While Off-Route**: Updates to whichever segment point happens to be closest.
- **Current Cue Behavior While Off-Route**: Cue progression continues blindly unless explicitly held.
- **Current Climb Behavior While Off-Route**: Evaluates climb progress without off-route freezing.
- **Current Loop/Intersection Behavior**: Snaps to intersecting or overlapping loops without heading compatibility or continuity penalties.
- **Known False Positives**: Tree cover or urban canyon GPS drift (> 35m for 1 second) immediately triggers false off-route alerts.
- **Known Missed Deviations**: Parallel service roads within 30m never trigger off-route despite opposite heading.

---

## 2. Target Architecture (Phase 7)

```
GPSAcceptedSample
      ↓
RouteMatcher
      ↓
RouteMatch (confidence, crossTrack, headingDifference)
      ↓
OffRouteEvidenceBuilder & OffRouteEvaluator
      ├── Cross-track hysteresis (40m suspected, 60m confirmed)
      ├── Consecutive point requirement (>= 3 ticks)
      ├── Duration persistence (>= 6.0 seconds)
      └── GPS accuracy weighting
      ↓
OffRouteStatus (.onRoute, .suspected, .offRoute, .rejoining)
      ↓
RejoinCandidateSearcher & RejoinEvaluator
      ├── Forward-progress priority window
      ├── Heading alignment (<= 60°)
      └── Loop/intersection ambiguity scoring
      ↓
NavigationEngine (reconciles cues, progress, notifications)
```

---

## 3. Git Baseline

- **Branch**: `feature/phase-7-off-route-rejoin`
- **Base Commit**: `31deb7901362dc3ca634826351d61dc625e15ce3`
- **Test Baseline**: 98 tests passing in `UltraNavTests`.
