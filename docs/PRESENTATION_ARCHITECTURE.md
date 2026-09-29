# Presentation Architecture & ViewState Contracts

## Overview
Phase 1N establishes a strict separation between domain engines/coordinators and SwiftUI presentation views using the ViewModel + Immutable ViewState pattern.

## Architecture Flow
```
Domain Layer (RideLifecycleCoordinator / Engines)
       │
       ▼ (AsyncStreams / Snapshots)
ViewModels (@Observable @MainActor)
       │
       ▼ (Pure transformation via Mappers)
Immutable ViewState
       │
       ▼ (Render only, zero domain dependencies)
SwiftUI Views
```

## ViewModels & ViewStates
1. **RideViewModel**: Manages ride controls, duration, moving time, status, paused/active state (`RideViewState`, `RideControlsState`).
2. **MetricsViewModel**: Manages formatted primary and secondary metric tiles with source and freshness (`MetricsViewState`, `MetricTileState`).
3. **NavigationViewModel**: Manages navigation phase, cue distance, turn icon, street name, off-route warnings, progress (`NavigationViewState`, `NavigationPhaseViewState`).
4. **RouteMapViewModel**: Manages breadcrumbs, route polyline, current location coordinate, camera framing (`RouteMapViewState`).
5. **ClimbViewModel**: Manages active climb progress, upcoming climbs, summit distance, gradient, elevation profiles (`ClimbViewState`).
6. **RouteLibraryViewModel**: Manages route listing, selection, import, and deletion (`RouteLibraryViewState`).
7. **AppViewModel**: Coordinates top-level presentation state, alerts, banners, and tab/screen selection (`AlertViewState`, `BannerViewState`).

## Formatting Layer
All conversions and formatting are centralized under `UltraNav/Presentation/Formatting/`:
- `UnitPreferences`: `.metric` vs `.imperial` unit support.
- `StandardFormatters`: Formatters for Duration, Speed, Distance, Elevation, and Gradient.
- `MetricDisplayValue`: Encapsulates display value, unit, and optional accessibility label.
