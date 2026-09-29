# UltraNav Degraded Operation Matrix

## Overview
A degradation occurs when one or more optional subsystems are unavailable or malfunctioning, while core cycling telemetry and workout recording remain fully active.

| Degraded Subsystem | Trigger | Engine State | UI Presentation | Ride Recording Status |
|:---|:---|:---|:---|:---|
| **Location** | GPS signal loss / multipath | `RideState.active` with `.locationUnavailable` | GPS Banner: "GPS Lost" | Moving time & sensors continue |
| **Bluetooth Sensors** | Peripheral disconnect / power off | `RideState.active` with `.sensorsUnavailable` | Dashed metric cards `-- W`, `-- RPM` | GPS speed & heart rate continue |
| **Navigation** | Route missing / corrupted | `NavigationState.inactive` | Map shows breadcrumbs only | Workout & metrics continue |
| **Climbs** | Route lacks elevation profile | `ClimbState.inactive` | ClimbPro tab disabled/hidden | Route turn guidance continues |
| **HealthKit Save** | Finalization write error | `RideState.completed` with `.workoutNotSaved` | Save Alert: "Saved locally" | Telemetry preserved on disk |
