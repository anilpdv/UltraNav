# Route Normalization Rules & Pipeline Specification

**Specification Version**: `route-normalization-v2`  
**Normalizer Component**: `RouteNormalizer`  

---

## 1. Multi-Stage Normalization Sequence

```
1. Content Selection (via StandardGPXContentSelector)
       ↓
2. Remove Empty Segments & Validate Non-Empty Content
       ↓
3. Coordinate Extraction & Bounds Verification
       ↓
4. Duplicate Sample Pruning (DuplicatePointPolicy.removeExactConsecutiveSamples)
       ↓
5. Segment Boundary Preservation (Zero distance jump across segments)
       ↓
6. Cumulative Distance Accumulation
       ↓
7. Elevation & Timestamp Association (Negative elevation preserved)
       ↓
8. Waypoint Normalization
       ↓
9. Bounding Box & Antimeridian Crossing Calculation
       ↓
10. Route Metadata Resolution with Precedence Hierarchy
       ↓
11. Deterministic SHA-256 Route Identity & Content Fingerprinting
       ↓
12. Canonical Route Validation (CanonicalRouteValidator)
```

---

## 2. Segment Distance Boundary Preservation Rule

When calculating cumulative distance across multiple segments:
- The cumulative distance of the first point of segment $N+1$ **strictly equals** the cumulative distance of the last point of segment $N$.
- The distance across the disconnected physical gap between segment $N$ end and segment $N+1$ start is **NOT** added to total ride distance.
- This eliminates artificial straight-line velocity spikes and false elevation jumps across GPS pause intervals or separated trail sections.
