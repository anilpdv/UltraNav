import Foundation

struct IntensityFactorCalculator: Sendable {
    func calculate(
        normalizedPowerWatts: Double?,
        ftp: FunctionalThresholdPower?
    ) -> Double? {
        guard let normalizedPowerWatts, let ftp else {
            return nil
        }
        guard ftp.watts > 0 else { return nil }

        let value = normalizedPowerWatts / ftp.watts
        return value.isFinite ? value : nil
    }
}

struct TrainingStressScoreCalculator: Sendable {
    func calculate(
        eligibleDurationSeconds: TimeInterval,
        normalizedPowerWatts: Double?,
        intensityFactor: Double?,
        ftp: FunctionalThresholdPower?
    ) -> Double? {
        guard eligibleDurationSeconds > 0,
              let np = normalizedPowerWatts,
              let ifVal = intensityFactor,
              let ftpVal = ftp else {
            return nil
        }
        guard ftpVal.watts > 0 else { return nil }

        let denominator = ftpVal.watts * 3600.0
        guard denominator > 0 else { return nil }

        let tss = (eligibleDurationSeconds * np * ifVal / denominator) * 100.0
        return (tss.isFinite && tss >= 0) ? tss : nil
    }
}
