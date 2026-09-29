import Foundation

struct NormalizedPowerCalculator: Sendable {
    let windowSeconds: Int
    let minimumDurationSeconds: Int

    init(windowSeconds: Int = 30, minimumDurationSeconds: Int = 30) {
        self.windowSeconds = windowSeconds
        self.minimumDurationSeconds = minimumDurationSeconds
    }

    func calculate(oneSecondPowerSeries: [Double?]) -> Double? {
        // Collect valid 30s rolling windows where all 30 values are present
        guard oneSecondPowerSeries.count >= minimumDurationSeconds else { return nil }

        var fourthPowers: [Double] = []

        var currentWindow: [Double] = []
        for sample in oneSecondPowerSeries {
            if let watts = sample, watts >= 0 {
                currentWindow.append(watts)
                if currentWindow.count > windowSeconds {
                    currentWindow.removeFirst()
                }
                if currentWindow.count == windowSeconds {
                    let avg = currentWindow.reduce(0.0, +) / Double(windowSeconds)
                    let p4 = pow(avg, 4.0)
                    if p4.isFinite {
                        fourthPowers.append(p4)
                    }
                }
            } else {
                // Gap in data resets the contiguous rolling window
                currentWindow.removeAll()
            }
        }

        guard !fourthPowers.isEmpty else { return nil }

        let meanFourthPower = fourthPowers.reduce(0.0, +) / Double(fourthPowers.count)
        guard meanFourthPower > 0, meanFourthPower.isFinite else { return 0 }

        let np = pow(meanFourthPower, 0.25)
        return np.isFinite ? np : nil
    }
}

struct NormalizedPowerAccumulator: Sendable {
    private let windowSeconds: Int
    private let minimumDurationSeconds: Int

    private var secondSeries: [Double?] = []
    private var lastRecordedSecond: Int?
    private var rideStartTime: Date?

    init(windowSeconds: Int = 30, minimumDurationSeconds: Int = 30) {
        self.windowSeconds = windowSeconds
        self.minimumDurationSeconds = minimumDurationSeconds
    }

    mutating func start(at date: Date) {
        rideStartTime = date
        secondSeries.removeAll()
        lastRecordedSecond = nil
    }

    mutating func consume(watts: Double?, at date: Date) {
        guard let start = rideStartTime else {
            rideStartTime = date
            secondSeries.append(watts)
            lastRecordedSecond = 0
            return
        }

        let secondOffset = max(0, Int(date.timeIntervalSince(start).rounded(.down)))
        let last = lastRecordedSecond ?? -1

        if secondOffset > last {
            // Fill any missed seconds with nil (missing gap)
            for _ in (last + 1)..<secondOffset {
                secondSeries.append(nil)
            }
            secondSeries.append(watts)
            lastRecordedSecond = secondOffset
        } else if secondOffset == last && !secondSeries.isEmpty {
            // Overwrite latest second bucket
            secondSeries[secondSeries.count - 1] = watts
        }
    }

    var normalizedPowerWatts: Double? {
        let calc = NormalizedPowerCalculator(
            windowSeconds: windowSeconds,
            minimumDurationSeconds: minimumDurationSeconds
        )
        return calc.calculate(oneSecondPowerSeries: secondSeries)
    }

    mutating func reset() {
        secondSeries.removeAll()
        lastRecordedSecond = nil
        rideStartTime = nil
    }
}
