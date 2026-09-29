import Foundation

struct CumulativeMetricTracker: Equatable, Sendable {
    struct SourceState: Equatable, Sendable {
        let source: MetricSource
        var lastRawValue: Double
        var lastMeasuredAt: Date
        var offset: Double
        var selectedTotalAtActivation: Double
    }

    private(set) var selectedSource: MetricSource?
    private(set) var displayedTotal: Double = 0
    private var sourceStates: [MetricSource: SourceState] = [:]

    mutating func selectSource(_ source: MetricSource, currentRawValue: Double, at date: Date) {
        if selectedSource == source { return }

        selectedSource = source

        let offset: Double
        if sourceStates.isEmpty && displayedTotal == 0 {
            displayedTotal = currentRawValue
            offset = 0
        } else {
            offset = displayedTotal - currentRawValue
        }

        sourceStates[source] = SourceState(
            source: source,
            lastRawValue: currentRawValue,
            lastMeasuredAt: date,
            offset: offset,
            selectedTotalAtActivation: displayedTotal
        )
    }

    mutating func consume(source: MetricSource, rawValue: Double, at date: Date) -> Double {
        guard rawValue.isFinite, rawValue >= 0 else { return displayedTotal }

        var state: SourceState
        if let existing = sourceStates[source] {
            state = existing
        } else {
            let offset: Double
            if sourceStates.isEmpty && displayedTotal == 0 {
                displayedTotal = rawValue
                offset = 0
            } else {
                offset = displayedTotal - rawValue
            }
            state = SourceState(
                source: source,
                lastRawValue: rawValue,
                lastMeasuredAt: date,
                offset: offset,
                selectedTotalAtActivation: displayedTotal
            )
        }

        // Reset detection: if raw cumulative value dropped significantly
        if rawValue < (state.lastRawValue - 10.0) {
            state.offset = displayedTotal - rawValue
        }

        state.lastRawValue = rawValue
        state.lastMeasuredAt = date
        sourceStates[source] = state

        if selectedSource == source || selectedSource == nil {
            let candidateTotal = rawValue + state.offset
            displayedTotal = max(displayedTotal, candidateTotal)
        }

        return displayedTotal
    }

    mutating func rebase(afterPauseAt date: Date) {
        for (source, state) in sourceStates {
            var updated = state
            updated.offset = displayedTotal - state.lastRawValue
            updated.selectedTotalAtActivation = displayedTotal
            sourceStates[source] = updated
        }
    }

    mutating func reset() {
        selectedSource = nil
        displayedTotal = 0
        sourceStates.removeAll()
    }
}
