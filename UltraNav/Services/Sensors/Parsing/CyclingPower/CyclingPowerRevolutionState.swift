import Foundation

/// State tracker and rollover math handler for Cycling Power crank and wheel revolution events.
struct CyclingPowerRevolutionState: Sendable {
    private(set) var lastCrankRevolutions: UInt16?
    private(set) var lastCrankEventTime: UInt16?

    mutating func calculateCadence(crankRevolutions: UInt16, crankEventTime: UInt16) -> Double? {
        defer {
            self.lastCrankRevolutions = crankRevolutions
            self.lastCrankEventTime = crankEventTime
        }

        guard let prevRev = lastCrankRevolutions, let prevTime = lastCrankEventTime else {
            return nil
        }

        let deltaRev: UInt16
        if crankRevolutions >= prevRev {
            deltaRev = crankRevolutions - prevRev
        } else {
            deltaRev = UInt16(truncatingIfNeeded: (UInt32(UInt16.max) + 1 - UInt32(prevRev) + UInt32(crankRevolutions)))
        }

        let deltaTime: UInt16
        if crankEventTime >= prevTime {
            deltaTime = crankEventTime - prevTime
        } else {
            deltaTime = UInt16(truncatingIfNeeded: (UInt32(UInt16.max) + 1 - UInt32(prevTime) + UInt32(crankEventTime)))
        }

        guard deltaRev > 0, deltaTime > 0 else {
            return nil
        }

        let timeInSeconds = Double(deltaTime) / 1024.0
        let rpm = (Double(deltaRev) / timeInSeconds) * 60.0

        if rpm >= 10.0 && rpm <= 220.0 {
            return rpm.rounded()
        }

        return nil
    }

    mutating func reset() {
        self.lastCrankRevolutions = nil
        self.lastCrankEventTime = nil
    }
}
