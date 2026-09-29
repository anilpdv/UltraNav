import Foundation

enum MetricKind: String, CaseIterable, Codable, Sendable {
    case speed
    case cumulativeDistance
    case heartRate
    case cadence
    case power
    case activeEnergy
    case altitude
    case elapsedTime
    case activeTime
    case movingTime
}

enum DerivedMetricKind: String, CaseIterable, Codable, Sendable {
    case averageSpeed
    case maximumSpeed
    case averageHeartRate
    case maximumHeartRate
    case averageCadence
    case maximumCadence
    case averagePower
    case maximumPower
    case normalizedPower
    case intensityFactor
    case trainingStressScore
}
