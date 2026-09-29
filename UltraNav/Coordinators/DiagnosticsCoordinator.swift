import Foundation

struct AnonymizedDiagnosticExportDTO: Codable, Sendable {
    let schemaVersion: String
    let generatedAt: Date
    let appState: String
    let subsystemHealth: [String: String]
    let counters: [String: Int]
    let gauges: [String: Double]
    let recentEventSummaries: [String]
    let failureCounts: [String: Int]
}

actor DiagnosticsCoordinator: DiagnosticExporting {
    private let observability: any ObservabilityProviding
    private let clock: any ClockProviding

    init(
        observability: any ObservabilityProviding,
        clock: any ClockProviding = SystemClock()
    ) {
        self.observability = observability
        self.clock = clock
    }

    func makeExport() async throws -> DiagnosticExport {
        let snap = await observability.snapshot()

        var healthMap: [String: String] = [:]
        for (subsystem, health) in snap.subsystemHealth {
            healthMap[subsystem.rawValue] = "\(health.status)"
        }

        var counterMap: [String: Int] = [:]
        for (counter, count) in snap.counters {
            counterMap[counter.rawValue] = count
        }

        var gaugeMap: [String: Double] = [:]
        for (gauge, val) in snap.gauges {
            gaugeMap[gauge.rawValue] = val
        }

        let eventSummaries: [String] = snap.recentEvents.map { event in
            "[\(event.category.rawValue)] \(event.severity): \(event.kind)"
        }

        var failureCounts: [String: Int] = [:]
        for failure in snap.recentFailures {
            failureCounts[failure.failureID.rawValue, default: 0] += failure.occurrenceCount
        }

        let dto = AnonymizedDiagnosticExportDTO(
            schemaVersion: "1.0",
            generatedAt: snap.generatedAt,
            appState: snap.applicationState.rawValue,
            subsystemHealth: healthMap,
            counters: counterMap,
            gauges: gaugeMap,
            recentEventSummaries: eventSummaries,
            failureCounts: failureCounts
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(dto)

        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: snap.generatedAt).replacingOccurrences(of: ":", with: "-")
        let fileName = "ultranav-diagnostics-\(dateString).json"

        return DiagnosticExport(fileName: fileName, data: data, contentType: "application/json")
    }
}
