# Phase 7 Implementation Map

## 1. Existing Off-Route Evaluator
- **File**: `UltraNav/Navigation/OffRoute/LegacyOffRouteEvaluator.swift`
- **Input**: `RouteMatch`, `OffRouteStatus`, `Date`
- **Threshold**: Fixed 35m off-route, 25m recovery
- **Consecutive Evidence**: None (single tick evaluation)
- **GPS-Quality Handling**: None
- **Ambiguity Handling**: None

## 2. Existing Off-Route State
- **Owner**: `NavigationEngine.swift` via `NavigationStateMachine`
- **States**: `.unknown`, `.onRoute`, `.suspected`, `.offRoute`, `.rejoining`
- **Snapshot Fields**: `offRouteStatus: OffRouteStatus`, `distanceToRouteMeters: Double?`
- **Notification Behavior**: Emits `.possibleDeviation`, `.offRoute`, `.routeRejoined`

## 3. Existing Rejoin Behavior
- **Candidate Search**: None (relies on live point match)
- **Progress Selection**: None
- **Heading Use**: Ignored during rejoin
- **Loop Handling**: None
- **Backtracking**: Uncontrolled

## 4. Existing Cue & Climb Handling
- **Cue Progression Off-Route**: Frozen during ambiguous matches
- **Alerts Off-Route**: Suppressed
- **Rejoin Reconciliation**: Needs explicit progress & cue update

## 5. Migration Decisions & New Components
- Create `UltraNav/Navigation/OffRoute/OffRouteConfiguration.swift`:
  - Parameterizes suspected/confirmed thresholds, consecutive tick counts, and confirmation duration.
- Create `UltraNav/Navigation/OffRoute/OffRouteEvidence.swift`:
  - Tracks running deviation duration, consecutive off-track samples, and GPS accuracy dampening.
- Create `UltraNav/Navigation/OffRoute/OffRouteEvaluator.swift`:
  - Stateful implementation of `OffRouteEvaluating` replacing `LegacyOffRouteEvaluator`.
- Create `UltraNav/Navigation/Rejoin/RejoinCandidate.swift`:
  - Structured model representing candidate rejoin geometry edges, along-track distance, cross-track offset, heading compatibility, and ambiguity score.
- Create `UltraNav/Navigation/Rejoin/RejoinCandidateSearcher.swift`:
  - Spatial candidate lookup around last known progress $[-50\text{m}, +500\text{m}]$ with heading filtering.
- Create `UltraNav/Navigation/Rejoin/RejoinEvaluator.swift`:
  - Evaluates whether candidate is ready for immediate rejoin vs requires consecutive tracking.
- Update `NavigationEngine.swift` and `AppContainer.swift` to use `OffRouteEvaluator()`.
- Delete `LegacyOffRouteEvaluator.swift` and update `check_architecture.sh`.
