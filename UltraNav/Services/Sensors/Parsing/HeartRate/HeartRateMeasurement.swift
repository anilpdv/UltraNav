import Foundation

/// Parsed typed representation of a Bluetooth Heart Rate Measurement.
struct HeartRateMeasurement: Equatable, Sendable {
    let beatsPerMinute: UInt16
    let sensorContactDetected: Bool?
    let energyExpendedJoules: UInt16?
    let rrIntervals: [Double]

    init(
        beatsPerMinute: UInt16,
        sensorContactDetected: Bool? = nil,
        energyExpendedJoules: UInt16? = nil,
        rrIntervals: [Double] = []
    ) {
        self.beatsPerMinute = beatsPerMinute
        self.sensorContactDetected = sensorContactDetected
        self.energyExpendedJoules = energyExpendedJoules
        self.rrIntervals = rrIntervals
    }
}
