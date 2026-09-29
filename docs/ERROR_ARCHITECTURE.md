# UltraNav Error Architecture & Recovery Model

## Overview
UltraNav implements a multi-tier, policy-driven error management and recovery pipeline designed specifically for outdoor cycling on watchOS. The system ensures that non-fatal or optional subsystem failures (such as a Bluetooth power meter disconnect, temporary GPS jitter, or missing climb profile) never terminate an active ride session.

```
Platform / Hardware Event
          │
          ▼
   Service Layer (Location / Workout / Sensor / Storage)
          │
          ▼
   Domain Failure Classification (FailureClassifying)
          │
          ├── FailureID (Stable diagnostic code)
          ├── FailureSeverity (Informational, Warning, High, Critical)
          ├── FailureImpact (OptionSet)
          └── FailureRecoverability (Automatic, Retryable, UserAction, Degraded, Fatal)
          │
          ▼
   Recovery Policy & Recommendation (RecoveryPolicy)
          │
          ▼
   Failure Recorder & Deduplication (FailureRecording)
          │
          ├── Bound History FIFO (100 items)
          ├── Deduplication by (FailureID, SensorID, RouteID, Operation)
          └── Time-based Alert Suppression
          │
          ▼
   Presentation & View Mapping (FailurePresentationMapper)
          │
          ├── User-facing title & message
          ├── Actionable RecoveryAction buttons
          └── Passive Degradation indicators
```

## Core Principles
1. **Never Fail The Ride For Optional Features**: If Bluetooth or Climb analysis fails, the ride continues with graceful degradation.
2. **Deterministic Classification**: Raw system errors (such as CoreLocation `CLError` or HealthKit `HKError`) never cross architectural boundaries. They are normalized into strong domain types.
3. **No Unbounded Retries**: Retries are governed by `AutomaticRetryPolicy` with exponential backoff and maximum attempts to avoid battery drain.
4. **Alert Deduplication**: Repeating identical failures within their suppression window increment occurrence counts in diagnostics without spamming the cyclist.
