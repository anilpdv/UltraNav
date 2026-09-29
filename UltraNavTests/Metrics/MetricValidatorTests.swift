import Foundation
import Testing
@testable import UltraNav

@Suite("MetricValidator Tests")
struct MetricValidatorTests {
    private let validator = StandardMetricValidator()

    @Test("Validates speed within standard bounds")
    func testSpeedValidation() {
        let now = Date()
        let validObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(12.5),
            source: .gps,
            measuredAt: now
        )
        #expect(validator.validate(validObs, policy: .standard).isAccepted)

        let zeroObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(0.0),
            source: .gps,
            measuredAt: now
        )
        #expect(validator.validate(zeroObs, policy: .standard).isAccepted)

        let negativeObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(-1.0),
            source: .gps,
            measuredAt: now
        )
        #expect(!validator.validate(negativeObs, policy: .standard).isAccepted)

        let excessiveObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(55.0),
            source: .gps,
            measuredAt: now
        )
        #expect(!validator.validate(excessiveObs, policy: .standard).isAccepted)
    }

    @Test("Validates heart rate and rejects zero or negative values")
    func testHeartRateValidation() {
        let now = Date()
        let validObs = MetricObservation(
            kind: .heartRate,
            value: .heartRateBeatsPerMinute(145),
            source: .healthKit,
            measuredAt: now
        )
        #expect(validator.validate(validObs, policy: .standard).isAccepted)

        let zeroObs = MetricObservation(
            kind: .heartRate,
            value: .heartRateBeatsPerMinute(0),
            source: .healthKit,
            measuredAt: now
        )
        #expect(!validator.validate(zeroObs, policy: .standard).isAccepted)

        let excessiveObs = MetricObservation(
            kind: .heartRate,
            value: .heartRateBeatsPerMinute(280),
            source: .healthKit,
            measuredAt: now
        )
        #expect(!validator.validate(excessiveObs, policy: .standard).isAccepted)
    }

    @Test("Validates power within configured bounds including zero")
    func testPowerValidation() {
        let now = Date()
        let zeroPower = MetricObservation(
            kind: .power,
            value: .powerWatts(0),
            source: .bluetooth(sensor: SensorIdentifier(rawValue: "pwr-1")),
            measuredAt: now
        )
        #expect(validator.validate(zeroPower, policy: .standard).isAccepted)

        let normalPower = MetricObservation(
            kind: .power,
            value: .powerWatts(350),
            source: .bluetooth(sensor: SensorIdentifier(rawValue: "pwr-1")),
            measuredAt: now
        )
        #expect(validator.validate(normalPower, policy: .standard).isAccepted)

        let acceptableNegativePower = MetricObservation(
            kind: .power,
            value: .powerWatts(-50),
            source: .bluetooth(sensor: SensorIdentifier(rawValue: "pwr-1")),
            measuredAt: now
        )
        #expect(validator.validate(acceptableNegativePower, policy: .standard).isAccepted)

        let extremePower = MetricObservation(
            kind: .power,
            value: .powerWatts(5000),
            source: .bluetooth(sensor: SensorIdentifier(rawValue: "pwr-1")),
            measuredAt: now
        )
        #expect(!validator.validate(extremePower, policy: .standard).isAccepted)
    }

    @Test("Rejects non-finite values and kind/value mismatches")
    func testInvalidTypes() {
        let now = Date()
        let nanObs = MetricObservation(
            kind: .speed,
            value: .speedMetersPerSecond(Double.nan),
            source: .gps,
            measuredAt: now
        )
        #expect(!validator.validate(nanObs, policy: .standard).isAccepted)

        let mismatchObs = MetricObservation(
            kind: .speed,
            value: .heartRateBeatsPerMinute(150),
            source: .gps,
            measuredAt: now
        )
        #expect(!validator.validate(mismatchObs, policy: .standard).isAccepted)
    }
}
