# Test Scenario Catalog

## 1. Ride Lifecycle Scenarios

### `RIDE-LIFECYCLE-001`: Complete Outdoor Ride
- **Given:** Location authorized, HealthKit authorized, Bluetooth optional.
- **When:** Prepare -> Start -> GPS samples arrive -> Finish.
- **Then:** Ride completes, workout session finalizes, location stops, snapshots freeze.

### `RIDE-LIFECYCLE-002`: Partial Startup Rollback
- **Given:** Workout starts successfully, but location updates fail to start.
- **When:** Start command executed.
- **Then:** Start fails, workout rolls back / cancels, ride remains idle.

### `RIDE-LIFECYCLE-003`: Pause & Resume
- **Given:** Active outdoor ride.
- **When:** User pauses ride -> Clock advances -> User resumes.
- **Then:** Active duration pauses, paused duration accumulates, tracking resumes seamlessly.

---

## 2. Route & Navigation Scenarios

### `NAV-SCENARIO-001`: Route Navigation & Cue Progression
- **Given:** Valid canonical route loaded with 3 turn cues.
- **When:** GPS coordinates progress along route.
- **Then:** Remaining distance decreases monotonically, active cue advances, on-route state maintained.

### `NAV-SCENARIO-002`: Off-Route & Rejoin
- **Given:** Active navigation along route.
- **When:** GPS moves > 35m away from closest route segment.
- **Then:** Off-route notification emitted, navigation remains active, distance from route increases.
- **When:** GPS returns within 15m of route.
- **Then:** Rejoin notification emitted, on-route tracking resumes.

---

## 3. Sensor & Degradation Scenarios

### `SENSOR-DEGRADE-001`: Unexpected Sensor Disconnect
- **Given:** Active ride with paired BLE Heart Rate sensor.
- **When:** Sensor emits `.disconnected` event.
- **Then:** Ride remains active, degraded sensor status flagged, recovery recommendations provided.

### `CLIMB-OPTIONAL-001`: Route Without Elevation
- **Given:** Active route import with 0 elevation data.
- **When:** Navigation starts.
- **Then:** Navigation continues normally, ClimbEngine marks climb features unavailable without error.
