# Phase 5 Baseline: Route Matching and Navigation Geometry

## 1. Overview
Audit of current route matching, geometry indexing, and progress calculation in UltraNav.

## 2. Component Inventory
- **`LegacyRouteMatcher.swift`**:
  - Algorithm: Unbounded $O(N)$ linear scan over all vertices (`route.points`).
  - Projection: Vertex snapping only (`closestIndex`). No segment perpendicular projection.
  - Progress: Clamped to vertex `cumulativeDistanceMeters` without segment fractional interpolation.
  - Cross-Track: Direct point-to-point Euclidean distance to the nearest vertex.
  - Heading comparison: `nil`.
  - Loop & Intersection handling: None. Unconditionally snaps to the globally closest vertex, jumping forward or backward arbitrarily.
- **`NavigationEngine.swift`**:
  - Consumes `LocationSample`.
  - Calls `routeMatcher.match(location: sample, route: route, previousMatch: lastMatch)`.
  - Computes progress percentage as `distanceAlongRoute / totalDistance`.

## 3. Defects & Limitations of Baseline
1. **Vertex Snapping Error**: On a 500m straight road segment between two sparse GPX points, rider cross-track distance appears up to 250m off even when perfectly on the centerline!
2. **Intersection Jumping**: At a figure-8 intersection or overlapping loop, the matcher snaps to whichever loop vertex is geometrically closer, destroying route completion and cue ordering.
3. **Performance Scalability**: Unbounded $O(N)$ iteration on every 1Hz GPS sample causes unnecessary CPU churn and battery drain on large routes (10,000+ points).
4. **Heading Agnostic**: Facing north on a two-way road can match a southbound segment if GPS drifts slightly closer to the wrong side.
