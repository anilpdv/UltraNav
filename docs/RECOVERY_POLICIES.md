# UltraNav Recovery Policies

## Automatic Retry Policies
Automatic retries are carefully throttled to prevent resource exhaustion and battery depletion:

| Subsystem | Maximum Attempts | Initial Delay | Multiplier | Maximum Delay | Behavior on Exhaustion |
|:---|:---:|:---:|:---:|:---:|:---|
| `Sensors` | 5 | 2.0s | 1.5x | 15.0s | Degrade to `.sensorsUnavailable` |
| `Location` | 3 | 1.0s | 2.0x | 10.0s | Degrade to `.locationUnavailable` |
| `Storage` | 3 | 0.5s | 2.0x | 5.0s | Prompt user to save locally |
| `Workout` | 2 | 1.0s | 2.0x | 5.0s | Prompt user / fallback to local storage |

## Recovery Actions
- `retry`: Re-executes the failed operation synchronously or asynchronously.
- `retryAfterDelay`: Schedules an exponential backoff attempt via `RecoveryCoordinator`.
- `continueWithoutSensors`: Marks sensor metrics as unavailable without stopping the ride.
- `continueWithoutNavigation`: Clears the active route and returns the navigation engine to an inactive state.
- `continueWithoutClimbData`: Disables ClimbPro analysis while preserving route navigation.
- `saveRideLocally`: Persists complete ride telemetry to local disk if HealthKit export fails.
- `resetRide`: Fully resets all engine states back to `.idle`.
