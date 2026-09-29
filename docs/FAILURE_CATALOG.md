# UltraNav Failure Catalog

| Failure ID | Subsystem | Severity | Impact | Recoverability | Default User Action |
|:---|:---|:---|:---|:---|:---|
| `LOCATION-AUTH-001` | Location | High / Critical | Blocks Prep / Degrades Ride | User Action Required | Open Settings / Allow Location |
| `LOCATION-DISABLED-001` | Location | High | Blocks Prep | User Action Required | Open Settings |
| `LOCATION-UNKNOWN-001` | Location | Warning | Degrades Active Ride | Automatic | Passive GPS Banner |
| `LOCATION-UPDATE-001` | Location | Warning / High | Blocks Start or Degrades | Retryable / Degraded | Retry / Dismiss |
| `WORKOUT-AUTH-001` | Workout | High | Blocks Prep & Start | User Action Required | Allow Health Access |
| `WORKOUT-PREP-001` | Workout | High | Blocks Start | Retryable | Retry / Reset Ride |
| `WORKOUT-START-001` | Workout | Critical | Blocks Start | Retryable | Retry Start / Reset Ride |
| `WORKOUT-PAUSE-001` | Workout | Warning | Degrades Active Ride | Retryable | Retry / Dismiss |
| `WORKOUT-RESUME-001` | Workout | Warning | Degrades Active Ride | Retryable | Retry / Dismiss |
| `WORKOUT-FINISH-001` | Workout | High | Threatens Persistence | Retryable | Save Locally / Retry |
| `WORKOUT-TERMINATED-001`| Workout | Critical | Threatens Active Session | Recoverable with Degradation | Save Locally / Dismiss |
| `WORKOUT-SAVE-001` | Workout | High | HealthKit Save Failed | Retryable | Save Locally / Finish |
| `SENSOR-BT-001` | Sensors | Warning | Blocks Sensors | User Action Required | Continue Without Sensors |
| `SENSOR-SCAN-001` | Sensors | Warning | Blocks Sensors | Retryable | Retry / Continue |
| `SENSOR-CONNECT-001` | Sensors | Warning | Blocks Sensors | Retryable | Reconnect / Continue |
| `SENSOR-DISCONNECT-001`| Sensors | Warning | Degrades Sensor Metric | Retryable | Reconnect / Continue |
| `SENSOR-PACKET-001` | Sensors | Informational | Discarded Sample | Automatic | None (Logged) |
| `NAV-ROUTE-001` | Navigation| High | Blocks Navigation | User Action Required | Select Route / Continue |
| `NAV-MATCH-001` | Navigation| Warning | Degrades Navigation | Automatic | Dismiss |
| `NAV-OFFROUTE-001` | Navigation| Warning | Off Route Alert | Automatic / User Action | Rejoin / Dismiss |
| `ROUTE-NOTFOUND-001` | Routes | High | Blocks Navigation | User Action Required | Select Route |
| `ROUTE-PARSE-001` | Routes | High | Blocks Route Import | User Action Required | Select Another GPX |
| `ROUTE-VALIDATION-001`| Routes | High | Blocks Route Import | User Action Required | Select Another GPX |
| `ROUTE-STORE-001` | Routes | High | Threatens Persistence | Retryable | Retry / Dismiss |
| `ROUTE-DUPLICATE-001` | Routes | Informational | None | Not Recoverable | Dismiss |
| `CLIMB-NO-ELEVATION` | Climb | Informational | ClimbPro Disabled | Not Recoverable | Continue Without Climbs |
| `CLIMB-ANALYSIS-001` | Climb | Warning | Climbs Unavailable | Recoverable with Degradation | Retry / Continue |
| `CLIMB-PROGRESS-001` | Climb | Warning | Climb Tracking Frozen | Automatic | Dismiss |
| `METRIC-OBS-001` | Metrics | Informational | Sample Discarded | Automatic | None (Logged) |
| `METRIC-STALE-001` | Metrics | Informational | Metric Marked Stale | Automatic | None (Logged) |
| `METRIC-AGGR-001` | Metrics | Warning | Derived Metric Degraded | Automatic | None (Logged) |
| `APP-DEP-001` | App | Critical | Blocks App Launch | Fatal | Contact Support |
| `APP-STORE-001` | App | High | Storage Unavailable | Retryable | Retry / Dismiss |
