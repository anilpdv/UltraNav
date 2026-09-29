import Foundation

/// State tracker and rollover math handler for CSC wheel and crank revolution events.
struct CSCRevolutionState: Sendable {
    private(set) var lastWheelRevolutions: UInt32?
    private(set) var lastWheelEventTime: UInt16?
    private(set) var lastCrankRevolutions: UInt16?
    private(set) var lastCrankEventTime: UInt16?
    var wheelCircumferenceMeters: Double = 2.105

    mutating func calculateSpeed(wheelRevolutions: UInt32, wheelEventTime: UInt16) -> Double? {
        defer {
            self.lastWheelRevolutions = wheelRevolutions
            self.lastWheelEventTime = wheelEventTime
        }

        guard let prevRev = lastWheelRevolutions, let prevTime = lastWheelEventTime else {
            return nil
        }

        let deltaRev: UInt32
        if wheelRevolutions >= prevRev {
            deltaRev = wheelRevolutions - prevRev
        } else {
            deltaRev = UInt32(truncatingIfNeeded: (UInt64(UInt32.max) + 1 - UInt64(prevRev) + UInt64(wheelRevolutions)))
        }

        let deltaTime: UInt16
        if wheelEventTime >= prevTime {
            deltaTime = wheelEventTime - prevTime
        } else {
            deltaTime = UInt16(truncatingIfNeeded: (UInt32(UInt16.max) + 1 - UInt32(prevTime) + UInt32(wheelEventTime)))
        }

        guard deltaRev > 0, deltaTime > 0 else {
            return nil
        }

        let timeInSeconds = Double(deltaTime) / 1024.0
        let mps = (Double(deltaRev) * wheelCircumferenceMeters) / timeInSeconds

        if mps >= 0.0 && mps <= 45.0 {
            return mps
        }

        return nil
    }

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
        self.lastWheelRevolutions = nil
        self.lastWheelEventTime = nil
        self.lastCrankRevolutions = nil
        self.lastCrankEventTime = nil
    }
}
