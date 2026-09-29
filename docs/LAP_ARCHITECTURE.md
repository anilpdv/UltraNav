# UltraNav Lap Subsystem Architecture (Phase 9)

## 1. Lap Structure & Invariants

Each lap represents a discrete ride interval, initiated either manually via user action or automatically via distance triggers (e.g., every 5 km).

```swift
struct LapRecord: Identifiable, Equatable, Sendable {
    let id: ID
    let number: Int
    let trigger: LapTrigger
    let startedAt: Date
    let endedAt: Date
    let startDistanceMeters: Double
    let endDistanceMeters: Double
    let summary: LapMetricsSummary
}
```

## 2. Invariants
- **Immutable Summaries**: When a lap completes, its `LapMetricsSummary` is permanently frozen and will not change if ride conditions change later.
- **Non-overlapping Intervals**: Lap intervals form a continuous partition of the ride without gaps or overlap.
- **Pause Handling**: Pausing freezes the active lap's moving time and distance accumulation. Resuming continues accumulating into the active lap.
- **Ride Finalization**: Ending a ride automatically finalizes the active in-progress lap into the completed laps list.
