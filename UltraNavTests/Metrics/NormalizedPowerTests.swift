import Foundation
import Testing
@testable import UltraNav

@Suite("NormalizedPower Tests")
struct NormalizedPowerTests {
    @Test("Calculates Normalized Power for constant power output")
    func testConstantPower() {
        let calc = NormalizedPowerCalculator(windowSeconds: 30, minimumDurationSeconds: 30)

        // 60 seconds of steady 250W
        let series = Array(repeating: Optional(250.0), count: 60)
        let np = calc.calculate(oneSecondPowerSeries: series)

        #expect(np != nil)
        #expect(abs((np ?? 0) - 250.0) < 0.5)
    }

    @Test("Returns nil if duration is less than minimum window")
    func testInsufficientDuration() {
        let calc = NormalizedPowerCalculator(windowSeconds: 30, minimumDurationSeconds: 30)

        // Only 20 seconds
        let series = Array(repeating: Optional(300.0), count: 20)
        let np = calc.calculate(oneSecondPowerSeries: series)

        #expect(np == nil)
    }

    @Test("Calculates Normalized Power reflecting variability penalty")
    func testVariablePowerHigherThanAverage() {
        let calc = NormalizedPowerCalculator(windowSeconds: 30, minimumDurationSeconds: 30)

        // Alternating 150W and 350W blocks
        var series: [Double?] = []
        for i in 0..<120 {
            let watts = (i % 60 < 30) ? 150.0 : 350.0
            series.append(watts)
        }

        let avg = series.compactMap { $0 }.reduce(0.0, +) / Double(series.count) // 250W average
        let np = calc.calculate(oneSecondPowerSeries: series)

        #expect(np != nil)
        #expect((np ?? 0) > avg) // NP must be higher than simple average for variable power
    }
}

@Suite("IntensityFactor and TSS Tests")
struct IntensityFactorAndTSSTests {
    private let ifCalc = IntensityFactorCalculator()
    private let tssCalc = TrainingStressScoreCalculator()

    @Test("Calculates Intensity Factor as NP / FTP")
    func testIntensityFactor() {
        guard let ftp = FunctionalThresholdPower(watts: 250) else {
            Issue.record("Failed to create FTP")
            return
        }

        let ifVal = ifCalc.calculate(normalizedPowerWatts: 200.0, ftp: ftp)
        #expect(ifVal != nil)
        #expect(abs((ifVal ?? 0) - 0.8) < 0.001)

        let ifOver = ifCalc.calculate(normalizedPowerWatts: 275.0, ftp: ftp)
        #expect(ifOver != nil)
        #expect(abs((ifOver ?? 0) - 1.1) < 0.001)
    }

    @Test("Calculates TSS correctly: 1 hour at FTP = 100 TSS")
    func testTSSAtFTPForOneHour() {
        guard let ftp = FunctionalThresholdPower(watts: 250) else {
            Issue.record("Failed to create FTP")
            return
        }

        let durationSeconds: TimeInterval = 3600.0 // 1 hour
        let np = 250.0
        let ifVal = 1.0

        let tss = tssCalc.calculate(
            eligibleDurationSeconds: durationSeconds,
            normalizedPowerWatts: np,
            intensityFactor: ifVal,
            ftp: ftp
        )

        #expect(tss != nil)
        #expect(abs((tss ?? 0) - 100.0) < 0.01)
    }

    @Test("Calculates TSS for 2 hours at 0.8 IF = 128 TSS")
    func testTSSForTwoHoursAt0_8IF() {
        guard let ftp = FunctionalThresholdPower(watts: 250) else {
            Issue.record("Failed to create FTP")
            return
        }

        // TSS = 2 * (0.8)^2 * 100 = 2 * 0.64 * 100 = 128
        let durationSeconds: TimeInterval = 7200.0 // 2 hours
        let np = 200.0
        let ifVal = 0.8

        let tss = tssCalc.calculate(
            eligibleDurationSeconds: durationSeconds,
            normalizedPowerWatts: np,
            intensityFactor: ifVal,
            ftp: ftp
        )

        #expect(tss != nil)
        #expect(abs((tss ?? 0) - 128.0) < 0.1)
    }
}
