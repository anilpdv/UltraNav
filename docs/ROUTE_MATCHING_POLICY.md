# UltraNav Route Matching Policy & Navigation Geometry Specification

## 1. Overview
The UltraNav navigation subsystem is designed for robust, low-power, offline GPS route tracking on Apple Watch. This document outlines the geometric and algorithmic principles governing the `RouteMatcher` and `RouteGeometryIndex`.

---

## 2. Geometry Primitives

### 2.1 Coordinate Space & Distance
- **Haversine Distance**: All geodesic distance calculations between raw coordinates use the spherical Haversine formula with Earth radius $R = 6,371,000\text{ m}$.
- **Initial Bearing**: Direction between two points is calculated using standard great-circle forward azimuth in degrees $[0^\circ, 360^\circ)$.

### 2.2 Directed Route Edges (`RouteGeometryEdge`)
A route consists of $N-1$ directed edges $E_i = (P_i \to P_{i+1})$, where:
- $i \in [0, N-2]$ is the 0-based edge index.
- $P_i$ and $P_{i+1}$ are consecutive `RoutePoint` objects containing coordinates and cumulative along-route distances.
- `startDistanceMeters` and `endDistanceMeters` provide immediate spatial bounds.
- `bearingDegrees` represents the orientation vector of the edge.
- `lengthMeters` represents the edge length.

---

## 3. Segment Projection (`RouteSegmentProjector`)

Given a GPS coordinate $C$ and an edge $E_i = (P_i \to P_{i+1})$:
1. Local equirectangular planar projection converts spherical coordinates to Cartesian displacement vectors $(dx, dy)$ centered at $P_i$:
   $$\Delta x = (\text{lon}_C - \text{lon}_{P_i}) \cdot \cos\left(\frac{\text{lat}_C + \text{lat}_{P_i}}{2}\right) \cdot \frac{\pi R}{180}$$
   $$\Delta y = (\text{lat}_C - \text{lat}_{P_i}) \cdot \frac{\pi R}{180}$$
2. The vector $v = P_{i+1} - P_i$ has components $(vx, vy)$.
3. Scalar projection parameter $t$ is computed:
   $$t = \frac{\Delta x \cdot vx + \Delta y \cdot vy}{vx^2 + vy^2}$$
4. Clamping is strictly applied:
   $$t_{\text{clamped}} = \max(0.0, \min(1.0, t))$$
5. Projected coordinate $C_{\text{proj}}$ is interpolated along the geodesic segment at fraction $t_{\text{clamped}}$.
6. Along-route distance:
   $$D_{\text{along}} = \text{startDistance} + t_{\text{clamped}} \cdot \text{length}$$
7. Cross-track distance is the geodesic distance from $C$ to $C_{\text{proj}}$.

---

## 4. Candidate Edge Indexing (`RouteGeometryIndex`)

To eliminate $O(N)$ whole-route searches on every 1 Hz location tick:
1. **Initial / Search Without Prior State**:
   - Evaluates all edges, spatial bounding boxes, or spatial grid buckets.
2. **Sequential Tracking (Bounded Locality Search)**:
   - When a valid `lastEdgeIndex` $k$ is known, the candidate window is restricted to:
     $$\text{candidates} = [\max(0, k - \text{backwardWindow}), \min(N-2, k + \text{forwardWindow})]$$
   - Default configuration: `forwardWindow = 8`, `backwardWindow = 2`.
   - If no candidate in the local window meets the acceptance threshold (e.g. cross-track distance $< 50\text{m}$), fallback to global recovery scan is triggered.

---

## 5. Multi-Factor Scoring & Confidence

For each candidate edge $E_i$ and projection result $R_i$:

### 5.1 Score Components
- **Cross-Track Score**: $S_{\text{cross}} = \text{crossTrackDistanceMeters} \cdot W_{\text{cross}}$ ($W_{\text{cross}} = 1.0$)
- **Heading Difference**: $\Delta \theta = \min(|\theta_{\text{GPS}} - \theta_{\text{edge}}|, 360^\circ - |\theta_{\text{GPS}} - \theta_{\text{edge}}|)$
- **Heading Penalty**: $S_{\text{head}} = (\Delta \theta / 180.0) \cdot W_{\text{head}}$ ($W_{\text{head}} = 20.0$)
- **Continuity Penalty**:
  - Ahead within window: $0.0$
  - Backward movement $(i < k)$: $(k - i) \cdot W_{\text{back}}$ ($W_{\text{back}} = 15.0$)
  - Forward jump $(i > k + 2)$: $(i - k) \cdot W_{\text{jump}}$ ($W_{\text{jump}} = 10.0$)
- **Total Penalty Score**:
  $$\text{Score} = S_{\text{cross}} + S_{\text{head}} + \text{Penalty}_{\text{continuity}}$$

Candidate with the lowest score is selected.

### 5.2 Confidence Classification (`RouteMatchingConfidence`)
- **`.high`**: Cross-track $\le 15\text{ m}$ AND (Heading diff $\le 45^\circ$ OR speed $< 1.5\text{ m/s}$).
- **`.medium`**: Cross-track $\le 30\text{ m}$ AND (Heading diff $\le 90^\circ$ OR speed $< 1.5\text{ m/s}$).
- **`.low`**: Cross-track $> 30\text{ m}$ OR Heading diff $> 90^\circ$.
- **`.ambiguous`**: Multiple candidates have near-identical lowest scores ($\Delta \text{Score} < 2.0$) with distinct segment indices.

---

## 6. Integration Rules
- **Thread Safety**: All geometric calculations and matching functions are pure, deterministic, and execute synchronously on `@MainActor` or in concurrency-safe domains without background thread hopping.
- **Memory Footprint**: `RouteGeometryIndex` caches edge arrays once per loaded route, minimizing allocation during 1 Hz active navigation.
