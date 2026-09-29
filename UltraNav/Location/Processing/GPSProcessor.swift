import Foundation

/// Deterministic, actor-isolated GPS processing pipeline managing sample acceptance, speed smoothing, movement classification, and distance accumulation.
actor GPSProcessor: GPSProcessing {
    private let configuration: GPSProcessingConfiguration
    private let timestampValidator: any GPSTimestampValidating
    private let accuracyValidator: any GPSAccuracyValidating
    private let plausibilityValidator: GPSPlausibilityValidator
    private let speedEstimator: any GPSSpeedEstimating
    private var speedSmoother: any GPSSpeedSmoothing
    private let movementClassifier: any MovementClassifying
    private var distanceAccumulator: any GPSDistanceAccumulating

    private var state: GPSProcessingState

    init(
        configuration: GPSProcessingConfiguration = .outdoorCycling,
        timestampValidator: any GPSTimestampValidating = GPSTimestampValidator(),
        accuracyValidator: any GPSAccuracyValidating = GPSAccuracyValidator(),
        distanceCalculator: any CoordinateDistanceCalculating = CoreLocationDistanceCalculator(),
        speedEstimator: any GPSSpeedEstimating = GPSSpeedEstimator(),
        speedSmoother: any GPSSpeedSmoothing = TimeWeightedSpeedSmoother(),
        movementClassifier: any MovementClassifying = MovementClassifier(),
        distanceAccumulator: any GPSDistanceAccumulating = GPSDistanceAccumulator()
    ) {
        self.configuration = configuration
        self.timestampValidator = timestampValidator
        self.accuracyValidator = accuracyValidator
        self.plausibilityValidator = GPSPlausibilityValidator(distanceCalculator: distanceCalculator)
        self.speedEstimator = speedEstimator
        self.speedSmoother = speedSmoother
        self.movementClassifier = movementClassifier
        self.distanceAccumulator = distanceAccumulator
        self.state = GPSProcessingState()
    }

    func send(_ command: GPSProcessorCommand) async {
        switch command {
        case .start(let at):
            state.mode = .recording
            state.lastReceivedTimestamp = at

        case .pause:
            state.mode = .paused
            speedSmoother.reset()
            state.currentSpeedMetersPerSecond = nil

        case .resume:
            state.mode = .recoveringFromPause
            speedSmoother.reset()
            state.consecutiveMovingEvidence = 0
            state.consecutiveStationaryEvidence = 0
            state.currentSpeedMetersPerSecond = nil

        case .locationUnavailable:
            state.mode = .recoveringFromOutage
            speedSmoother.reset()
            state.currentSpeedMetersPerSecond = nil

        case .locationAvailable:
            if state.mode == .recoveringFromOutage || state.mode == .paused {
                // Remain in recovery until first valid sample arrives
            } else if state.mode != .finished && state.mode != .idle {
                state.mode = .recording
            }

        case .finish:
            state.mode = .finished
            speedSmoother.reset()

        case .reset:
            state = GPSProcessingState()
            speedSmoother.reset()
            distanceAccumulator.reset()
        }
    }

    func process(_ sample: LocationSample, receivedAt: Date) async -> GPSProcessingResult {
        state.sequence += 1
        let seq = state.sequence
        state.lastReceivedTimestamp = receivedAt

        // 1. Check Processor Mode
        switch state.mode {
        case .idle:
            return .ignored(GPSIgnoredSample(sample: sample, reason: .notRecording, sequence: seq))
        case .finished:
            return .ignored(GPSIgnoredSample(sample: sample, reason: .finished, sequence: seq))
        case .paused:
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .processorPaused, sequence: seq))
        case .recording, .recoveringFromPause, .recoveringFromOutage:
            break
        }

        // 2. Validate Coordinate Structurally
        guard sample.coordinate.isGeographicallyValid else {
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .invalidCoordinate, sequence: seq))
        }

        // 3. Validate Horizontal Accuracy
        let accuracyVal = accuracyValidator.validate(sample, configuration: configuration)
        let quality: GPSQuality
        switch accuracyVal {
        case .invalid:
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .invalidHorizontalAccuracy, sequence: seq))
        case .tooPoor(let actual, let maxAcc):
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .accuracyTooPoor(actualMeters: actual, maximumMeters: maxAcc), sequence: seq))
        case .accepted(let q):
            quality = q
        }

        // 4. Validate Timestamp (Age & Monotonicity against last accepted sample)
        let timeVal = timestampValidator.validate(
            sampleTimestamp: sample.timestamp,
            receivedAt: receivedAt,
            previousAcceptedTimestamp: state.lastAcceptedSample?.timestamp,
            configuration: configuration
        )
        switch timeVal {
        case .tooOld(let age):
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .timestampTooOld(ageSeconds: age), sequence: seq))
        case .outOfOrder:
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .outOfOrderTimestamp, sequence: seq))
        case .duplicate:
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .duplicateTimestamp, sequence: seq))
        case .insufficientDelta:
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .insufficientTimeDelta, sequence: seq))
        case .valid:
            break
        }

        // 5. Check if recovering from pause or outage
        let isRecovering = state.mode == .recoveringFromPause || state.mode == .recoveringFromOutage
        if isRecovering {
            state.mode = .recording
            let speedEstimate = speedEstimator.estimate(
                current: sample,
                previous: nil,
                distanceMeters: nil,
                timeDeltaSeconds: nil,
                configuration: configuration
            )
            if let spd = speedEstimate.metersPerSecond {
                speedSmoother.add(speedMetersPerSecond: spd, at: sample.timestamp)
            }
            let smoothedSpeed = speedSmoother.value(at: sample.timestamp) ?? speedEstimate.metersPerSecond
            state.currentSpeedMetersPerSecond = smoothedSpeed
            state.currentSpeedMeasuredAt = sample.timestamp

            let movementEvidence = MovementEvidence(
                selectedSpeedMetersPerSecond: smoothedSpeed,
                positionDistanceMeters: 0.0,
                accuracyOverlap: false,
                timeDeltaSeconds: 0.0
            )
            let movementResult = movementClassifier.classify(
                evidence: movementEvidence,
                previousState: state.movementState,
                consecutiveMovingEvidence: state.consecutiveMovingEvidence,
                consecutiveStationaryEvidence: state.consecutiveStationaryEvidence,
                configuration: configuration
            )
            state.movementState = movementResult.state
            state.consecutiveMovingEvidence = movementResult.consecutiveMovingEvidence
            state.consecutiveStationaryEvidence = movementResult.consecutiveStationaryEvidence

            state.lastAcceptedSample = sample
            state.lastAcceptedSequence = seq
            state.acceptedSampleCount += 1

            let accepted = GPSAcceptedSample(
                sample: sample,
                quality: quality,
                selectedSpeedMetersPerSecond: smoothedSpeed,
                movementState: state.movementState,
                distanceIncrementMeters: 0.0,
                totalDistanceMeters: state.totalDistanceMeters,
                sequence: seq,
                suitableForRideMetrics: true,
                suitableForNavigation: true
            )
            return .accepted(accepted)
        }

        // 6. Plausibility & Distance Calculation against previous accepted sample
        guard let prevSample = state.lastAcceptedSample else {
            // First accepted sample establishing initial anchor
            let speedEstimate = speedEstimator.estimate(
                current: sample,
                previous: nil,
                distanceMeters: nil,
                timeDeltaSeconds: nil,
                configuration: configuration
            )
            if let spd = speedEstimate.metersPerSecond {
                speedSmoother.add(speedMetersPerSecond: spd, at: sample.timestamp)
            }
            let smoothedSpeed = speedSmoother.value(at: sample.timestamp) ?? speedEstimate.metersPerSecond
            state.currentSpeedMetersPerSecond = smoothedSpeed
            state.currentSpeedMeasuredAt = sample.timestamp

            let movementEvidence = MovementEvidence(
                selectedSpeedMetersPerSecond: smoothedSpeed,
                positionDistanceMeters: 0.0,
                accuracyOverlap: false,
                timeDeltaSeconds: 0.0
            )
            let movementResult = movementClassifier.classify(
                evidence: movementEvidence,
                previousState: state.movementState,
                consecutiveMovingEvidence: state.consecutiveMovingEvidence,
                consecutiveStationaryEvidence: state.consecutiveStationaryEvidence,
                configuration: configuration
            )
            state.movementState = movementResult.state
            state.consecutiveMovingEvidence = movementResult.consecutiveMovingEvidence
            state.consecutiveStationaryEvidence = movementResult.consecutiveStationaryEvidence

            state.lastAcceptedSample = sample
            state.lastAcceptedSequence = seq
            state.acceptedSampleCount += 1

            let accepted = GPSAcceptedSample(
                sample: sample,
                quality: quality,
                selectedSpeedMetersPerSecond: smoothedSpeed,
                movementState: movementResult.state,
                distanceIncrementMeters: 0.0,
                totalDistanceMeters: state.totalDistanceMeters,
                sequence: seq,
                suitableForRideMetrics: true,
                suitableForNavigation: true
            )
            return .accepted(accepted)
        }

        let timeDelta = sample.timestamp.timeIntervalSince(prevSample.timestamp)
        let isLongGap = timeDelta > configuration.maximumTimeDeltaForDistanceSeconds

        let plausibility = plausibilityValidator.validate(
            current: sample,
            previous: prevSample,
            configuration: configuration
        )

        let distanceMeters: Double
        let accuracyOverlap: Bool

        switch plausibility {
        case .invalidTimeDelta, .nonFiniteCalculation:
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .nonFiniteCalculation, sequence: seq))
        case .implausibleDistanceJump(let jump):
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .implausibleDistanceJump(distanceMeters: jump), sequence: seq))
        case .implausibleSpeed(let spd):
            state.rejectedSampleCount += 1
            return .rejected(GPSRejectedSample(sample: sample, reason: .implausibleSpeed(metersPerSecond: spd), sequence: seq))
        case .plausible(let dist, _, let overlap):
            distanceMeters = dist
            accuracyOverlap = overlap
        }

        // 7. Speed Estimation & Smoothing
        let speedEstimate = speedEstimator.estimate(
            current: sample,
            previous: prevSample,
            distanceMeters: distanceMeters,
            timeDeltaSeconds: timeDelta,
            configuration: configuration
        )
        if let spd = speedEstimate.metersPerSecond {
            speedSmoother.add(speedMetersPerSecond: spd, at: sample.timestamp)
        }
        let smoothedSpeed = speedSmoother.value(at: sample.timestamp) ?? speedEstimate.metersPerSecond
        state.currentSpeedMetersPerSecond = smoothedSpeed
        state.currentSpeedMeasuredAt = sample.timestamp

        // 8. Movement Classification with Hysteresis
        let movementEvidence = MovementEvidence(
            selectedSpeedMetersPerSecond: smoothedSpeed,
            positionDistanceMeters: distanceMeters,
            accuracyOverlap: accuracyOverlap,
            timeDeltaSeconds: timeDelta
        )
        let movementResult = movementClassifier.classify(
            evidence: movementEvidence,
            previousState: state.movementState,
            consecutiveMovingEvidence: state.consecutiveMovingEvidence,
            consecutiveStationaryEvidence: state.consecutiveStationaryEvidence,
            configuration: configuration
        )
        state.movementState = movementResult.state
        state.consecutiveMovingEvidence = movementResult.consecutiveMovingEvidence
        state.consecutiveStationaryEvidence = movementResult.consecutiveStationaryEvidence

        // 9. Distance Accumulation & Anchor Advancement
        let bridgeAllowed = !isLongGap
        let accumulationResult = distanceAccumulator.evaluate(
            previous: prevSample,
            current: sample,
            movementState: movementResult.state,
            distanceMeters: distanceMeters,
            bridgeAllowed: bridgeAllowed
        )

        state.totalDistanceMeters = accumulationResult.totalMeters
        if accumulationResult.shouldAdvanceAnchor {
            state.lastAcceptedSample = sample
            state.lastAcceptedSequence = seq
        }
        state.acceptedSampleCount += 1

        let accepted = GPSAcceptedSample(
            sample: sample,
            quality: quality,
            selectedSpeedMetersPerSecond: smoothedSpeed,
            movementState: movementResult.state,
            distanceIncrementMeters: accumulationResult.incrementMeters,
            totalDistanceMeters: accumulationResult.totalMeters,
            sequence: seq,
            suitableForRideMetrics: true,
            suitableForNavigation: true
        )
        return .accepted(accepted)
    }

    func snapshot() async -> GPSProcessingSnapshot {
        let speedFreshness: MetricFreshness?
        if let lastMeasurement = state.currentSpeedMeasuredAt,
           let now = state.lastReceivedTimestamp,
           state.currentSpeedMetersPerSecond != nil {
            speedFreshness = MetricFreshness.freshness(
                for: lastMeasurement,
                now: now,
                staleThresholdSeconds: configuration.speedFreshnessSeconds,
                expiredThresholdSeconds: configuration.maximumSampleAgeSeconds
            )
        } else {
            speedFreshness = nil
        }

        return GPSProcessingSnapshot(
            mode: state.mode,
            totalDistanceMeters: state.totalDistanceMeters,
            currentSpeedMetersPerSecond: state.currentSpeedMetersPerSecond,
            speedFreshness: speedFreshness,
            movementState: state.movementState,
            lastAcceptedSample: state.lastAcceptedSample,
            acceptedSampleCount: state.acceptedSampleCount,
            rejectedSampleCount: state.rejectedSampleCount
        )
    }
}
