# Phase 5 Implementation Map

## Current Matcher
- **File**: `UltraNav/Navigation/Matching/LegacyRouteMatcher.swift`
- **Type**: `LegacyRouteMatcher`
- **Input**: `LocationSample`, `Route`, `previousMatch: RouteMatch?`
- **Output**: `RouteMatch?`
- **Algorithm**: $O(N)$ linear vertex distance search
- **Complexity**: $O(N)$ per location sample
- **Previous-match use**: None (ignored)

## Target Architecture
1. **`RouteGeometryIndex`**:
   - `RouteSegment`: Represents directed edge from $P_i \to P_{i+1}$ with:
     - `startCoordinate`, `endCoordinate`
     - `startDistanceMeters`, `lengthMeters`, `endDistanceMeters`
     - `bearingDegrees`
     - `boundingBox: GeoBoundingBox`
   - Spatial query: Bounded spatial lookup (candidate search window around `lastMatchedIndex` or spatial bounding box).
2. **Segment Projection Engine**:
   - `RouteSegmentProjector`: Computes point-to-segment projection using vector projection (cross-track distance, fractional $t \in [0, 1]$, projected coordinate, along-track distance).
3. **`RouteMatcher`**:
   - `RouteMatchingConfiguration`: Thresholds for search radius, heading weight, continuity penalty, max forward jump, max backward jump.
   - Candidate scoring:
     $$\text{Score} = w_{\text{cross}} \cdot d_{\text{cross}} + w_{\text{heading}} \cdot \Delta\theta + \text{ContinuityPenalty}(\Delta s)$$
   - Disambiguation: Hysteresis on progress advancement preventing loop jumping.
   - Match confidence: `.high`, `.medium`, `.low`, `.ambiguous`.
4. **`NavigationEngine` Integration**:
   - Uses `RouteGeometryIndex` cached when route is loaded.
   - Provides deterministic updates to `NavigationSnapshot`.

## Migration Decisions
- `LegacyRouteMatcher` -> Replaced by `RouteMatcher`
- `FakeRouteMatcher` -> Retained for unit test mocking
