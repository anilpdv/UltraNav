# ClimbEngine Architecture & Boundary Specification

## Overview

The `ClimbEngine` coordinates elevation profile construction, climb candidate detection, standardized classification, active climb tracking, and live progress metrics without coupling to raw GPS coordinates, direct file access, or XML parsing.

## Component Responsibilities

1. **ElevationProfileBuilding (`LegacyElevationProfileBuilder`)**:
   - Constructs an `ElevationProfile` from the canonical domain `Route`.
   - Computes cumulative ascent, descent, min elevation, and max elevation.
   - Validates elevation points and fails with `ClimbFailure.noElevationData` or `ClimbFailure.insufficientElevationData`.

2. **ClimbDetecting (`LegacyClimbDetector`)**:
   - Scans an `ElevationProfile` for sustained positive grade segments (grade >= 3.0%, min distance 400m, min net gain 20m, score >= 1200).
   - Produces unclassified `ClimbCandidate` models with slice-by-slice gradient profiles.

3. **ClimbClassifying (`LegacyClimbClassifier`)**:
   - Categorizes candidates into standard `ClimbCategory` (`.uncategorized`, `.category4`, `.category3`, `.category2`, `.category1`, `.horsCategorie`) based on score (`distance * grade%`) and elevation gain.

4. **ClimbAnalysisService (`actor ClimbAnalysisService`)**:
   - An isolated background actor executing profile building, candidate detection, and candidate assembly off the main UI actor.

5. **ActiveClimbSelecting (`StandardActiveClimbSelector`)**:
   - Evaluates route progress distance to identify active climbs, approaching climbs (within 500m), upcoming climbs, and completed climb IDs monotonically.

6. **ClimbProgressCalculating (`StandardClimbProgressCalculator`)**:
   - Computes distance into climb, distance remaining, elevation remaining, current gradient slice, fraction completed, and progress quality.

7. **ClimbEngine (`@MainActor final class ClimbEngine: ClimbEngineProviding`)**:
   - Consumes `Route`, `NavigationSnapshot`, and `LocationSample`.
   - Publishes immutable `ClimbSnapshot` stream and discrete `ClimbNotification` stream.

## Data Flow Diagram

```mermaid
flowchart TD
    Route[Canonical Route] --> CAS[ClimbAnalysisService (Actor)]
    CAS --> EP[ElevationProfile]
    CAS --> CD[ClimbDetecting]
    CAS --> CC[ClimbClassifying]
    CAS --> Climbs[Array of Climb Models]
    
    Climbs --> CE[ClimbEngine (@MainActor)]
    NavSnap[NavigationSnapshot] --> CE
    LocSample[LocationSample] --> CE
    
    CE --> CS[ClimbSnapshot Stream]
    CE --> CN[ClimbNotification Stream]
    
    CS --> Adapter[LegacyClimbAdapter]
    Adapter --> View[ClimbProView]
```
