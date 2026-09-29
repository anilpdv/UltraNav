# UltraNav Turn Detection & Cue Progression Policy

## 1. Overview
This specification details the offline geometric algorithms for turn detection, maneuver classification, deterministic cue generation, and stateful cue progression in UltraNav.

---

## 2. Bearing Windowing & Angle Normalization

### 2.1 Signed Angle Representation
All angular differences $\Delta\theta$ are normalized to the signed domain $[-180.0^\circ, 180.0^\circ)$:
- $\Delta\theta > 0$: Rightward turn.
- $\Delta\theta < 0$: Leftward turn.
- $\Delta\theta = 0$: Straight ahead.

### 2.2 Distance-Windowed Bearing Smoothing (`RouteBearingProfile`)
Rather than comparing raw consecutive point bearings (which are susceptible to GPS noise and micro-jitter), the turn angle at route distance $d$ is computed by evaluating weighted average entry and exit bearings across a distance window $W = 25\text{ m}$:
- **Entry Bearing**: Geodesic azimuth vector over $[d - W, d]$.
- **Exit Bearing**: Geodesic azimuth vector over $[d, d + W]$.
- **Turn Angle**: $\Delta\theta(d) = \text{normalize}(\theta_{\text{exit}} - \theta_{\text{entry}})$.

---

## 3. Turn Candidate Detection & Noise Filtering (`TurnCandidateDetector`)

- **Step Sampling**: Samples $\Delta\theta(d)$ at step intervals $\Delta d = 5\text{ m}$.
- **Minimum Turn Threshold**: $|\Delta\theta(d)| \ge 20^\circ$.
- **Edge Buffering**: Suppresses detections within the first and last $15\text{ m}$ of a route segment.
- **Peak Selection**: For contiguous zones exceeding the turn threshold, the point of maximum absolute angular deflection is extracted as the turn candidate.

---

## 4. Compound Turn Resolution (`TurnCandidateMerger`)

- **Cluster Threshold**: $25\text{ m}$.
- Multiple candidate turns occurring within $25\text{ m}$ of each other (e.g. roundabout entry/exit, double chicanes) are merged:
  - $\text{Net Angle} = \text{normalize}(\sum \Delta\theta_i)$.
  - The location is assigned to the dominant candidate (highest deflection).

---

## 5. Maneuver Classification (`ManeuverClassifier`)

| Angular Range $|\Delta\theta|$ | Classification |
|---|---|
| $0^\circ \le |\Delta\theta| < 20^\circ$ | `.continueStraight` |
| $20^\circ \le \Delta\theta < 45^\circ$ | `.slightRight` |
| $-45^\circ < \Delta\theta \le -20^\circ$ | `.slightLeft` |
| $45^\circ \le \Delta\theta < 120^\circ$ | `.right` |
| $-120^\circ < \Delta\theta \le -45^\circ$ | `.left` |
| $120^\circ \le \Delta\theta < 160^\circ$ | `.sharpRight` |
| $-160^\circ < \Delta\theta \le -120^\circ$ | `.sharpLeft` |
| $|\Delta\theta| \ge 160^\circ$ | `.uTurn` |

---

## 6. Cue Progression State Machine (`CueProgressor`)

### 6.1 Distance Thresholds
- **Approach Threshold**: $100\text{ m}$ (emits `.approachingCue(cue)` exactly once).
- **Immediate Threshold**: $25\text{ m}$ (emits `.immediateCue(cue)` exactly once).
- **Passed Threshold**: $d_{\text{user}} \ge d_{\text{cue}} + 15\text{ m}$ (marks cue as passed and selects next cue).

### 6.2 Backtracking & Ambiguity Invariants
- **Monotonic Passed List**: Cues once marked passed are never unmarked during a ride, preventing repeated alert triggers if the rider turns around or backtracks.
- **Ambiguous Match Hold**: If `RouteMatch.confidence` is `.ambiguous` or `.low` with high cross-track error ($> 50\text{ m}$), cue advancement and notifications are paused until valid on-route tracking resumes.
