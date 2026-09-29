# UltraNav Subsystem Health

## Subsystems
- `app`: Overall container and top-level coordinator lifecycle.
- `ride`: Core ride session execution and timing.
- `location`: GPS tracking and CoreLocation streaming.
- `workout`: HealthKit workout session builder and persistence.
- `sensors`: Bluetooth peripheral management, GATT discovery, and telemetry.
- `routeLibrary`: Local route persistence, indexing, and GPX file management.
- `navigation`: Route progress matching, off-route evaluation, and turn cue tracking.
- `metrics`: Rolling metric calculations and freshness tracking.
- `climb`: Elevation profile analysis and active climb tracking.
- `presentation`: UI state projection and view models.

## Health Statuses
1. `unknown`: Subsystem has not yet registered or completed initialization.
2. `healthy`: Operational and functioning normally within expected parameters.
3. `degraded`: Operational with non-critical impairments (e.g. sensor disconnected during ride).
4. `unavailable`: Feature or hardware unavailable by design (e.g. bluetooth powered off, or no route loaded).
5. `failed`: Critical error blocking subsystem operation.
