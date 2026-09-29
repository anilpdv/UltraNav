# UltraNav Observability Architecture

Phase 1Q introduces a comprehensive, deterministic, privacy-first observability architecture for UltraNav on watchOS.

```
Services, Engines, Coordinators
            │
            ├── Structured Log Events (Logging)
            ├── State Transitions (StateTransitionTrace)
            ├── Operation Durations (OperationTrace via MonotonicClock)
            ├── Counters (CounterMetric)
            ├── Gauges (GaugeMetric)
            ├── Event-Drop Reports (EventDropRecord)
            └── Subsystem Health (SubsystemHealth)
                         │
                         ▼
             ObservabilityCenter (Actor)
                         │
               ┌─────────┴─────────┐
               ▼                   ▼
         SystemLogger      Diagnostic Snapshot (Bounded)
         (OSLog + Redact)          │
                                   ▼
                        DiagnosticsCoordinator (JSON Export)
```

## Key Principles

1. **Clock Separation**:
   - Wall-Clock (`ClockProviding` / `SystemClock` / `TestClock`): Used for timestamps, historical logs, file records.
   - Monotonic Clock (`MonotonicClockProviding` / `SystemMonotonicClock` / `TestMonotonicClock`): Used for elapsed duration measurements, timeouts, and operation timers. Never affected by wall-clock changes or daylight savings.

2. **Structured Logging**:
   - Log levels: `trace`, `debug`, `information`, `notice`, `warning`, `error`, `critical`.
   - Log categories: `app`, `dependencyInjection`, `ride`, `location`, `workout`, `bluetooth`, `routeImport`, `routeStore`, `navigation`, `metrics`, `climb`, `presentation`, `recovery`, `concurrency`, `observability`.
   - Privacy tiers: `.public`, `.privateData`, `.sensitive` (redacted in public logs).

3. **Bounded Memory Footprint**:
   - `ObservabilityCenter` maintains a hard bounded FIFO buffer of diagnostic events (default 250 items).
   - High frequency updates use lightweight in-memory counters (`CounterMetric`) and gauges (`GaugeMetric`).

4. **Zero Domain Pollution**:
   - Pure domain models (`RideStateMachine`, `NavigationStateMachine`, `Route`, `Climb`) do not log or hold dependencies on observability.
   - State transition and operation outcome logging are handled by their containing engines, services, or coordinators.
