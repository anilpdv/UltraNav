import Foundation

protocol MetricArbitrating: Sendable {
    func select(
        kind: MetricKind,
        candidates: [MetricObservation],
        currentSelection: MetricSelection?,
        policy: MetricSourcePolicy,
        freshnessEvaluator: any MetricFreshnessEvaluating,
        freshnessConfig: MetricFreshness,
        at date: Date,
        recoveryState: inout [MetricKind: Date]
    ) -> MetricArbitrationResult
}

final class MetricArbitrator: MetricArbitrating, @unchecked Sendable {
    func select(
        kind: MetricKind,
        candidates: [MetricObservation],
        currentSelection: MetricSelection?,
        policy: MetricSourcePolicy,
        freshnessEvaluator: any MetricFreshnessEvaluating = MetricFreshnessEvaluator(),
        freshnessConfig: MetricFreshness = .standard,
        at date: Date,
        recoveryState: inout [MetricKind: Date]
    ) -> MetricArbitrationResult {
        let prefs = policy.preferences(for: kind)

        // Evaluate candidates
        let evaluatedCandidates: [MetricSourceCandidate] = candidates.compactMap { obs in
            let avail = freshnessEvaluator.availability(
                kind: kind,
                measuredAt: obs.measuredAt,
                currentDate: date,
                configuration: freshnessConfig
            )

            // Calculate preference rank
            var prefRank = Int.max
            for (index, pref) in prefs.enumerated() {
                if pref.matches(source: obs.source, kind: kind) {
                    prefRank = index
                    break
                }
            }

            let qualityRank: Int
            switch obs.quality {
            case .valid: qualityRank = 0
            case .derived: qualityRank = 1
            case .estimated: qualityRank = 2
            case .uncertain: qualityRank = 3
            }

            return MetricSourceCandidate(
                observation: obs,
                availability: avail,
                preferenceRank: prefRank,
                qualityRank: qualityRank
            )
        }

        // Available candidates first, otherwise fallback to stale candidates
        let availableCandidates = evaluatedCandidates.filter { $0.availability == .available }
        let candidatePool = !availableCandidates.isEmpty ? availableCandidates : evaluatedCandidates.filter { $0.availability == .stale }

        guard !candidatePool.isEmpty else {
            // No candidates at all
            recoveryState.removeValue(forKey: kind)
            if let current = currentSelection {
                return MetricArbitrationResult(
                    selection: nil,
                    transition: .currentSourceUnavailable(from: current.source, to: nil)
                )
            }
            return MetricArbitrationResult(selection: nil, transition: nil)
        }

        // Sort candidate pool by:
        // 1. Preference Rank (lower is better)
        // 2. Is current source (stickiness if equal rank)
        // 3. Quality Rank (lower is better)
        // 4. measuredAt (newer is better)
        let sorted = candidatePool.sorted { a, b in
            if a.preferenceRank != b.preferenceRank {
                return a.preferenceRank < b.preferenceRank
            }
            let aIsCurrent = currentSelection?.source == a.observation.source
            let bIsCurrent = currentSelection?.source == b.observation.source
            if aIsCurrent != bIsCurrent {
                return aIsCurrent
            }
            if a.qualityRank != b.qualityRank {
                return a.qualityRank < b.qualityRank
            }
            return a.observation.measuredAt > b.observation.measuredAt
        }

        guard let bestCandidate = sorted.first else {
            return MetricArbitrationResult(selection: nil, transition: nil)
        }

        // If no current selection exists, select best immediately
        guard let current = currentSelection else {
            recoveryState.removeValue(forKey: kind)
            let newSelection = MetricSelection(
                source: bestCandidate.observation.source,
                observation: bestCandidate.observation,
                selectedAt: date,
                preferenceRank: bestCandidate.preferenceRank
            )
            return MetricArbitrationResult(
                selection: newSelection,
                transition: .initiallySelected(bestCandidate.observation.source)
            )
        }

        // If same source selected, update observation
        if current.source == bestCandidate.observation.source {
            recoveryState.removeValue(forKey: kind)
            let updatedSelection = MetricSelection(
                source: bestCandidate.observation.source,
                observation: bestCandidate.observation,
                selectedAt: current.selectedAt,
                preferenceRank: bestCandidate.preferenceRank
            )
            return MetricArbitrationResult(selection: updatedSelection, transition: nil)
        }

        // Current source is different. Check if current source is stale or unavailable
        let currentCandidate = evaluatedCandidates.first { $0.observation.source == current.source }
        let currentAvail = currentCandidate?.availability ?? .unavailable

        if currentAvail != .available {
            // Immediate fallback away from stale / unavailable source
            recoveryState.removeValue(forKey: kind)
            let newSelection = MetricSelection(
                source: bestCandidate.observation.source,
                observation: bestCandidate.observation,
                selectedAt: date,
                preferenceRank: bestCandidate.preferenceRank
            )
            let transition: MetricSourceTransition = currentAvail == .stale
                ? .currentSourceStale(from: current.source, to: bestCandidate.observation.source)
                : .currentSourceUnavailable(from: current.source, to: bestCandidate.observation.source)
            return MetricArbitrationResult(selection: newSelection, transition: transition)
        }

        // Current source is still available, but a better (lower preference rank) source is available
        if bestCandidate.preferenceRank < current.preferenceRank {
            // Apply switch-back delay hysteresis
            if let firstSeen = recoveryState[kind] {
                if date.timeIntervalSince(firstSeen) >= policy.switchBackDelaySeconds {
                    // Hysteresis elapsed, perform switch-back!
                    recoveryState.removeValue(forKey: kind)
                    let newSelection = MetricSelection(
                        source: bestCandidate.observation.source,
                        observation: bestCandidate.observation,
                        selectedAt: date,
                        preferenceRank: bestCandidate.preferenceRank
                    )
                    return MetricArbitrationResult(
                        selection: newSelection,
                        transition: .preferredSourceAvailable(from: current.source, to: bestCandidate.observation.source)
                    )
                }
            } else {
                recoveryState[kind] = date
            }
        } else {
            recoveryState.removeValue(forKey: kind)
        }

        // Keep current source
        let preservedObservation = currentCandidate?.observation ?? current.observation
        let keptSelection = MetricSelection(
            source: current.source,
            observation: preservedObservation,
            selectedAt: current.selectedAt,
            preferenceRank: current.preferenceRank
        )
        return MetricArbitrationResult(selection: keptSelection, transition: nil)
    }
}
