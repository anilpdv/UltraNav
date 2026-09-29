import Foundation

struct SubsystemHealthRowViewState: Equatable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let statusText: String
    let isHealthy: Bool
    let activeDegradationCount: Int
}

struct CounterRowViewState: Equatable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let count: Int
}

struct GaugeRowViewState: Equatable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let valueText: String
}

struct DiagnosticsViewState: Equatable, Sendable {
    let appStateText: String
    let lastUpdatedText: String
    let subsystemHealthList: [SubsystemHealthRowViewState]
    let counterList: [CounterRowViewState]
    let gaugeList: [GaugeRowViewState]
    let recentEventCount: Int
    let recentFailureCount: Int

    static let empty = DiagnosticsViewState(
        appStateText: "Unknown",
        lastUpdatedText: "--",
        subsystemHealthList: [],
        counterList: [],
        gaugeList: [],
        recentEventCount: 0,
        recentFailureCount: 0
    )
}
