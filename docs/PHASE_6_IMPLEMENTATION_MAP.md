# Phase 6 Implementation Map

## 1. Existing Cue Model
- **File**: `UltraNav/Domain/Navigation/NavigationCue.swift`
- **Identity**: `UUID`
- **Maneuver Type**: `NavigationManeuver` (`continueStraight`, `slightLeft`, `left`, `sharpLeft`, `slightRight`, `right`, `sharpRight`, `uTurn`, `arrive`, `unknown`)
- **Distance Field**: `routeDistanceMeters: Double`
- **Instruction Field**: `instruction: String?`
- **Source Distinction**: Needs explicit source tagging if GPX waypoint vs generated geometry cue.

## 2. Existing Cue Generation
- **File**: `UltraNav/Navigation/Cues/LegacyCueAdapter.swift`
- **Input**: `Route`
- **Bearing Calculation**: None (stubbed).
- **Turn Threshold**: None.
- **Noise Filtering**: None.
- **Candidate Merging**: None.
- **Segment-Boundary Behavior**: None.

## 3. Existing Cue Progression
- **File**: `UltraNav/Navigation/Cues/LegacyCueAdapter.swift`
- **Current Cue State**: `CueProgress` (`nextCue`, `distanceToNextCueMeters`, `passedCueIDs`)
- **Approach Threshold**: None.
- **Immediate Threshold**: Fixed -25m offset.
- **Passed Threshold**: Instantaneous `< userProgressDist`.
- **Notification Suppression**: None.
- **Backtracking Behavior**: No suppression; passes again or drops.

## 4. Existing Presentation
- **Cue Instruction Mapping**: `NavigationViewStateMapper.swift` maps to `CueViewState` with localized text and accessibility label.
- **Maneuver Icon Mapping**: `NavigationPhaseViewState.swift` maps `ManeuverViewState` to SF Symbols (`arrow.turn.up.left`, `arrow.uturn.backward`, etc.).
- **Distance Formatting**: Handled via `UnitPreferences` formatter.
- **Haptic Mapping**: Handled via `NavigationNotificationCoordinator`.

## 5. Migration Decisions & New Components
- Create `UltraNav/Navigation/Cues/TurnDetection/RouteBearingProfile.swift`:
  - Computes edge bearings, cumulative distances, smoothed bearing across distance windows (`bearingWindowDistanceMeters = 20.0` m), and angular deviations.
- Create `UltraNav/Navigation/Cues/TurnDetection/TurnCandidateDetector.swift`:
  - Scans bearing profiles, suppresses noise (micro-segments $< 2$ m, transient spikes), extracts raw candidates $(\Delta\theta \ge 20^\circ)$.
- Create `UltraNav/Navigation/Cues/TurnDetection/TurnCandidateMerger.swift`:
  - Merges nearby candidate turns within clustering window ($\le 25$ m) into compound turns, computing net angle change and dominant maneuver.
- Create `UltraNav/Navigation/Cues/TurnDetection/ManeuverClassifier.swift`:
  - Normalizes signed turn angle in degrees $[-180^\circ, 180^\circ]$ and maps to `NavigationManeuver`.
- Create `UltraNav/Navigation/Cues/TurnDetection/NavigationCueBuilder.swift`:
  - Synthesizes deterministic UUIDs from route identity and along-track distance, attaches coordinates and semantic instructions (e.g. "In 100m, turn left"), and outputs ordered `[NavigationCue]`.
- Create `UltraNav/Navigation/Cues/Progression/CueProgressor.swift`:
  - State machine advancing cues based on stable `RouteMatch.distanceAlongRouteMeters`, managing approach ($100$ m), immediate ($25$ m), and passed ($+15$ m) states without alert replays on backtracking.
- Create `UltraNav/Navigation/Cues/Progression/CueProgressSnapshot.swift`:
  - Comprehensive snapshot model with alerts, active cue, distance, and passed cue set.
- Update `NavigationEngine.swift` and `AppContainer.swift` to use `NavigationCueBuilder` / `CueProgressor`.
- Remove `LegacyCueAdapter.swift` and add to forbidden legacy symbols.
