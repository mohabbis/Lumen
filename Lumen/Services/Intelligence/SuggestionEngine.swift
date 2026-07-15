import Foundation

// MARK: - Suggestion Engine
// A lightweight, on-device *scored heuristic* layer for "Lumen noticed".
//
// This is the successor to the hardcoded time-of-day → scene switch that used
// to live in `HomeDashboardView`. Instead of a fixed mapping, the engine scores
// every real scene against the current ambient state and the user's own run
// history, then surfaces the highest-confidence one — but only when it clears a
// calm threshold, so Lumen still stays quiet when nothing is clearly relevant.
//
// The core is a pure value type with no SwiftData / SwiftUI dependency so it can
// be unit-tested exhaustively (see `SuggestionEngineTests`). The dashboard builds
// `SuggestionCandidate`s from `@Query`'d `Scene`s and `ExecutionEvent`s and hands
// them in.
//
// Explainability is a hard requirement (see ROADMAP Phase 1): every scored scene
// carries the `SuggestionFactor`s that produced its confidence, so the reasoning
// surface can show a signal list a person can read and disagree with.

// MARK: - Presence

enum PresenceState: Equatable {
    case home
    case away
    case unknown
}

// MARK: - Candidate

/// A value-type view of a `Scene` the engine can score without touching SwiftData.
struct SuggestionCandidate: Equatable, Identifiable {
    let sceneName: String
    let geofenceTrigger: GeofenceTrigger
    let isFavorite: Bool
    /// Past successful-or-attempted runs bucketed by hour-of-day (0...23).
    let runsByHour: [Int: Int]
    let totalRuns: Int

    var id: String { sceneName }

    init(
        sceneName: String,
        geofenceTrigger: GeofenceTrigger = .none,
        isFavorite: Bool = false,
        runsByHour: [Int: Int] = [:]
    ) {
        self.sceneName = sceneName
        self.geofenceTrigger = geofenceTrigger
        self.isFavorite = isFavorite
        self.runsByHour = runsByHour
        self.totalRuns = runsByHour.values.reduce(0, +)
    }
}

// MARK: - Factor & Suggestion

/// One explainable reason contributing to a scene's score.
struct SuggestionFactor: Equatable, Identifiable {
    let id: String
    let label: String
    let detail: String
    /// Additive contribution to the raw score, in points (roughly 0...0.45 each).
    let contribution: Double
}

/// A scored scene: its normalized confidence plus the factors behind it.
struct SceneSuggestion: Equatable, Identifiable {
    let sceneName: String
    let confidence: Double          // 0...1
    let habitRuns: Int              // runs observed in the current hour window
    let factors: [SuggestionFactor]

    var id: String { sceneName }
}

// MARK: - Engine

struct SuggestionEngine: Equatable {

    let timeOfDay: TimeOfDay
    let presence: PresenceState
    let reachableDevices: Int
    let hourOfDay: Int
    let candidates: [SuggestionCandidate]
    /// Sensory profile constraints from user preferences
    let dailySuggestionLimit: Int?
    let pausedSuggestions: Bool

    /// Minimum confidence before Lumen will surface a suggestion at all. Below
    /// this, the calm default is to stay quiet rather than nudge on a hunch.
    static let surfaceThreshold: Double = 0.2

    // MARK: Public API

    /// All candidates scored and sorted, highest confidence first. Deterministic:
    /// ties break on run volume, then scene name, so the UI never flickers.
    func rankedSuggestions() -> [SceneSuggestion] {
        guard !pausedSuggestions else { return [] }
        
        return candidates
            .map(score(_:))
            .sorted { lhs, rhs in
                if lhs.confidence != rhs.confidence { return lhs.confidence > rhs.confidence }
                if lhs.habitRuns != rhs.habitRuns { return lhs.habitRuns > rhs.habitRuns }
                return lhs.sceneName.localizedCaseInsensitiveCompare(rhs.sceneName) == .orderedAscending
            }
    }

    /// The single scene worth suggesting now, or `nil` if nothing clears the
    /// calm threshold, or if daily limit has been reached.
    func topSuggestion() -> SceneSuggestion? {
        guard !pausedSuggestions else { return nil }
        
        let best = rankedSuggestions().first
        guard let best = best, best.confidence >= Self.surfaceThreshold else { return nil }
        
        // Enforce daily suggestion limit from sensory profile
        if let limit = dailySuggestionLimit, limit <= 0 {
            return nil
        }
        
        return best
    }

    // MARK: Scoring

    private func score(_ candidate: SuggestionCandidate) -> SceneSuggestion {
        var factors: [SuggestionFactor] = []

        if let timeFactor = timeAffinityFactor(candidate) {
            factors.append(timeFactor)
        }

        let habitRuns = runsInHourWindow(candidate)
        if let habitFactor = habitFactor(runs: habitRuns) {
            factors.append(habitFactor)
        }

        if let presenceFactor = presenceFactor(candidate) {
            factors.append(presenceFactor)
        }

        if candidate.isFavorite {
            factors.append(
                SuggestionFactor(
                    id: "favorite",
                    label: "Favorite",
                    detail: "You marked this a favorite",
                    contribution: 0.1
                )
            )
        }

        if reachableDevices > 0 {
            factors.append(
                SuggestionFactor(
                    id: "devices",
                    label: "Devices ready",
                    detail: "\(reachableDevices) reachable now",
                    contribution: 0.1
                )
            )
        }

        let raw = factors.reduce(0) { $0 + $1.contribution }
        let confidence = min(1.0, max(0.0, raw))

        return SceneSuggestion(
            sceneName: candidate.sceneName,
            confidence: confidence,
            habitRuns: habitRuns,
            factors: factors
        )
    }

    private func timeAffinityFactor(_ candidate: SuggestionCandidate) -> SuggestionFactor? {
        let name = candidate.sceneName.lowercased()
        guard Self.keywords(for: timeOfDay).contains(where: { name.contains($0) }) else { return nil }
        return SuggestionFactor(
            id: "time",
            label: "Time of day",
            detail: "Fits \(timeOfDay.name.lowercased())",
            contribution: 0.45
        )
    }

    private func habitFactor(runs: Int) -> SuggestionFactor? {
        guard runs > 0 else { return nil }
        // Volume-scaled and capped: 1 run → 0.12, saturating at 0.4 for 4+ runs.
        let contribution = min(0.4, 0.12 * Double(runs))
        return SuggestionFactor(
            id: "habit",
            label: "Usual routine",
            detail: "Run \(runs)× around this hour",
            contribution: contribution
        )
    }

    private func presenceFactor(_ candidate: SuggestionCandidate) -> SuggestionFactor? {
        switch (presence, candidate.geofenceTrigger) {
        case (.away, .onDeparture):
            return SuggestionFactor(
                id: "presence",
                label: "Away routine",
                detail: "You're away and this runs on departure",
                contribution: 0.3
            )
        case (.home, .onArrival):
            return SuggestionFactor(
                id: "presence",
                label: "Arrival routine",
                detail: "You're home and this runs on arrival",
                contribution: 0.2
            )
        default:
            return nil
        }
    }

    /// Sum of historical runs within ±1 hour of the current hour, wrapping the
    /// 24-hour clock (so 00:00 neighbors 23:00).
    private func runsInHourWindow(_ candidate: SuggestionCandidate) -> Int {
        let window = [(hourOfDay + 23) % 24, hourOfDay % 24, (hourOfDay + 1) % 24]
        return window.reduce(0) { $0 + (candidate.runsByHour[$1] ?? 0) }
    }

    // MARK: Keyword table

    private static func keywords(for time: TimeOfDay) -> [String] {
        switch time {
        case .dawn:      return ["morning", "wake", "sunrise", "dawn"]
        case .morning:   return ["morning", "wake", "sunrise"]
        case .afternoon: return ["afternoon", "focus", "work", "midday"]
        case .evening:   return ["evening", "sunset", "dinner", "relax", "movie", "wind down", "winddown"]
        case .night:     return ["night", "sleep", "bed", "goodnight"]
        }
    }
}
