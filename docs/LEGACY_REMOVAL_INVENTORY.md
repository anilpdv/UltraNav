# Legacy Removal Inventory (Phase 1S)

This inventory records all obsolete classes, singletons, presentation adapters, and deprecated files removed during Phase 1S to achieve complete architecture lock-in for UltraNav.

---

## 1. Removed Legacy Singletons & Platform Managers

| Legacy Symbol | Previous Location | Replacement Production Component | Architectural Rationale |
|:---|:---|:---|:---|
| `CyclingRideEngine.shared` | `UltraNav/Services/Cycling/CyclingRideEngine.swift` | `RideEngine` (`UltraNav/Engines/Ride/RideEngine.swift`) | Removed monolithic God-object singleton with mutable global state. Replaced by unidirectional, value-snapshot `RideEngine` composed within `AppContainer`. |
| `BluetoothSensorManager.shared` | `UltraNav/Services/Cycling/BluetoothSensorManager.swift` | `BluetoothService` (`UltraNav/Services/Sensors/CoreBluetooth/BluetoothService.swift`) | Removed global singleton wrapping CoreBluetooth. Replaced by `SensorProviding` actor-isolated adapter emitting typed `SensorServiceEvent` streams. |
| `WorkoutSessionManager.shared` | `UltraNav/Services/Cycling/WorkoutSessionManager.swift` | `HealthKitService` (`UltraNav/Services/Workout/HealthKit/HealthKitService.swift`) | Removed singleton managing HKWorkoutSession. Replaced by `WorkoutProviding` adapter emitting typed `WorkoutServiceEvent` streams. |
| `RouteLibraryManager.shared` | `UltraNav/Services/GPX/RouteLibraryManager.swift` | `RouteStore` & `RouteLibraryEngine` | Removed singleton with direct disk I/O and in-memory caches. Replaced by structured `RouteStore` and unidirectional `RouteLibraryEngine`. |

---

## 2. Removed Legacy Presentation Adapters

| Legacy Adapter | Previous Location | Modern Replacement | Architectural Rationale |
|:---|:---|:---|:---|
| `LegacyRideEngineAdapter` | `UltraNav/Presentation/Ride/LegacyRideEngineAdapter.swift` | `RideViewModel` (`UltraNav/Presentation/Ride/RideViewModel.swift`) | Removed temporary bridge mutating `CyclingRideEngine`. Presentation layer now binds directly to `RideViewModel` driven by `RideSnapshot`. |
| `LegacyNavigationAdapter` | `UltraNav/Presentation/Navigation/LegacyNavigationAdapter.swift` | `NavigationViewModel` (`UltraNav/Presentation/Navigation/NavigationViewModel.swift`) | Removed legacy navigation state adapter. Replaced by direct `NavigationSnapshot` consumption via `NavigationViewModel`. |
| `LegacyMetricsAdapter` | `UltraNav/Presentation/Metrics/LegacyMetricsAdapter.swift` | `MetricsViewModel` (`UltraNav/Presentation/Metrics/MetricsViewModel.swift`) | Removed bridge synthesizing metric views. Replaced by pure `MetricsViewStateMapper` mapping `MetricsSnapshot` to `MetricsViewState`. |
| `LegacyClimbAdapter` | `UltraNav/Presentation/Climb/LegacyClimbAdapter.swift` | `ClimbViewModel` (`UltraNav/Presentation/Climb/ClimbViewModel.swift`) | Removed bridge wrapping climb state. Replaced by direct `ClimbSnapshot` stream processing via `ClimbViewModel`. |
| `LegacyRouteLibraryAdapter` | `UltraNav/Presentation/Routes/LegacyRouteLibraryAdapter.swift` | `RouteLibraryViewModel` (`UltraNav/Presentation/Routes/RouteLibraryViewModel.swift`) | Removed temporary adapter bridging `RouteLibraryManager`. Replaced by `RouteLibraryViewModel` observing `RouteLibraryEngine`. |

---

## 3. Removed Deprecated GPX / Model Files

| Removed File | Previous Location | Modern Replacement | Rationale |
|:---|:---|:---|:---|
| `GPXRoute.swift` | `UltraNav/Models/GPXRoute.swift` | `Route` (`UltraNav/Domain/Routes/Route.swift`) | Superseded by canonical, immutable `Route` value type with bounding boxes and normalized coordinates. |
| `GPXParser.swift` | `UltraNav/Services/GPX/GPXParser.swift` | `GPXParserAdapter` (`UltraNav/Services/GPX/GPXParserAdapter.swift`) | Superseded by hermetic, protocol-driven `GPXParsing` adapter and pipeline normalizer. |
| `GPXParserTests.swift` | `UltraNavTests/GPXParserTests.swift` | `RouteImporterTests` & `GPXParserAdapterTests` | Replaced by comprehensive pipeline unit and regression tests. |
| `CyclingRideEngineTests.swift` | `UltraNavTests/CyclingRideEngineTests.swift` | `RideEngineTests`, `RideLifecycleRegressionTests` | Replaced by actor-safe engine unit and integration test suites. |

---

## 4. Retained Legacy Adapters (Behind Domain Protocols)

As specified in Phase 1S.77, the following algorithmic legacy adapters remain strictly contained behind domain protocols and will be modernized in future algorithmic phases (Phases 3–6):

| Algorithm Adapter | Location | Protocol Implemented | Scheduled Modernization Phase |
|:---|:---|:---|:---|
| `LegacyCueAdapter` | `UltraNav/Navigation/Cues/LegacyCueAdapter.swift` | `NavigationCueProviding`, `CueProgressing` | Phase 5 (Turn-by-Turn Cue Engine) |
| `LegacyRouteMatcher` | `UltraNav/Navigation/Matching/LegacyRouteMatcher.swift` | `RouteMatching` | Phase 5 (Segment Projection & Map Matching) |
| `LegacyOffRouteEvaluator` | `UltraNav/Navigation/OffRoute/LegacyOffRouteEvaluator.swift` | `OffRouteEvaluating` | Phase 5 (Hysteresis & Off-Route Engine) |
| `LegacyRouteCompletionEvaluator` | `UltraNav/Navigation/Completion/LegacyRouteCompletionEvaluator.swift` | `RouteCompletionEvaluating` | Phase 5 (Route Completion Engine) |
| `LegacyElevationProfileBuilder` | `UltraNav/Climb/Profile/LegacyElevationProfileBuilder.swift` | `ElevationProfileBuilding` | Phase 6 (Elevation Profile Engine) |
| `LegacyClimbDetector` | `UltraNav/Climb/Detection/LegacyClimbDetector.swift` | `ClimbDetecting` | Phase 6 (Climb Detection Engine) |
| `LegacyClimbClassifier` | `UltraNav/Climb/Classification/LegacyClimbClassifier.swift` | `ClimbClassifying` | Phase 6 (Climb Classification Engine) |
| `LegacyCSCParserAdapter` | `UltraNav/Services/Sensors/Parsers/LegacyCSCParserAdapter.swift` | `CSCParsing` | Phase 3 (Bluetooth Pipeline) |
| `LegacyCyclingPowerParserAdapter` | `UltraNav/Services/Sensors/Parsers/LegacyCyclingPowerParserAdapter.swift` | `CyclingPowerParsing` | Phase 3 (Bluetooth Pipeline) |
| `LegacyHeartRateParserAdapter` | `UltraNav/Services/Sensors/Parsers/LegacyHeartRateParserAdapter.swift` | `HeartRateParsing` | Phase 3 (Bluetooth Pipeline) |
