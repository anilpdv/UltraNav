# Phase 3 Implementation Map

## 1. Location Service
- **File**: `UltraNav/Services/Location/LocationService.swift`
- **Framework Manager**: `CLLocationManager`
- **Converter**: `CoreLocationSampleConverter.swift`
- **Event Type**: `LocationServiceEvent` (`.locationReceived(LocationSample)`)

## 2. Location Domain Models
- **File**: `UltraNav/Domain/Location/LocationSample.swift`
- **Properties**: `coordinate`, `altitudeMeters`, `horizontalAccuracyMeters`, `verticalAccuracyMeters`, `speedMetersPerSecond`, `speedAccuracyMetersPerSecond`, `courseDegrees`, `courseAccuracyDegrees`, `timestamp`
- **Invariants**: Strict finite checks, horizontal accuracy >= 0, negative speeds normalized to `nil`.

## 3. GPS Processing Core Models
- `GPSQuality`: `.excellent` (<=5m), `.good` (<=10m), `.usable` (<=25m), `.poor` (>25m)
- `GPSAcceptedSample`: Sample, quality, selected speed, movement state, distance increment, total distance, sequence number.
- `GPSRejectedSample`: Sample, typed `GPSSampleRejectionReason`, sequence number.
- `GPSIgnoredSample`: Sample, typed `GPSIgnoredReason` (`.notRecording`, `.finished`), sequence number.
- `GPSProcessingResult`: `.accepted(GPSAcceptedSample)`, `.rejected(GPSRejectedSample)`, `.ignored(GPSIgnoredSample)`.
- `GPSProcessingConfiguration`: Configurable thresholds (`.outdoorCycling`).
- `GPSProcessingState` & `GPSProcessingSnapshot`: Comprehensive mutable and immutable snapshot representations.

## 4. Processing Subsystems
1. **Validation**:
   - `GPSTimestampValidating` & `GPSTimestampValidator`: Age clamping, monotonic timestamp ordering, duplicate detection.
   - `GPSAccuracyValidating` & `GPSAccuracyValidator`: Finite, non-negative, <= max horizontal accuracy threshold.
   - `GPSPlausibilityValidator`: Non-finite distance/speed, maximum plausible speed (35 m/s).
2. **Speed**:
   - `GPSSpeedEstimating` & `GPSSpeedEstimator`: Selects between platform reported and position derived.
   - `GPSSpeedSmoothing` & `TimeWeightedSpeedSmoother`: Time-bounded sliding window smoother.
3. **Movement**:
   - `MovementClassifying` & `MovementClassifier`: Stationary (<=0.8 m/s, 3 samples), Moving (>=1.5 m/s, 2 samples), accuracy overlap evaluation.
4. **Distance**:
   - `GPSDistanceAccumulating` & `GPSDistanceAccumulator`: Moving sample accumulation, zero-drift stationary handling, anchor advancement.
5. **Processor Actor**:
   - `GPSProcessing` & `GPSProcessor`: Actor isolating state, processing 18-stage pipeline, managing lifecycle (`start`, `pause`, `resume`, `outage`, `finish`, `reset`).

## 5. Coordinator & Engine Integration
- `RideDataCoordinator`: Intercepts `LocationServiceEvent`, processes via `GPSProcessor`, fans `.accepted` to `MetricsEngine` and `NavigationEngine`.
- `MetricsEngine`: Receives `.gps(GPSAcceptedSample)`, stores speed and total distance observations.
