import XCTest
@testable import Lumen

final class SuggestionEngineTests: XCTestCase {

    // MARK: - Helpers

    private func engine(
        time: TimeOfDay = .evening,
        presence: PresenceState = .home,
        reachable: Int = 0,
        hour: Int = 19,
        candidates: [SuggestionCandidate]
    ) -> SuggestionEngine {
        SuggestionEngine(
            timeOfDay: time,
            presence: presence,
            reachableDevices: reachable,
            hourOfDay: hour,
            candidates: candidates
        )
    }

    // MARK: - Candidate

    func testCandidateTotalRunsSumsBuckets() {
        let candidate = SuggestionCandidate(sceneName: "Wind Down", runsByHour: [8: 2, 20: 3])
        XCTAssertEqual(candidate.totalRuns, 5)
    }

    // MARK: - Time affinity

    func testEveningKeywordSurfacesSceneWithConfidence() {
        let e = engine(
            time: .evening,
            reachable: 2,
            candidates: [SuggestionCandidate(sceneName: "Evening")]
        )
        let top = e.topSuggestion()
        XCTAssertEqual(top?.sceneName, "Evening")
        // keyword 0.45 + devices 0.1
        XCTAssertEqual(top?.confidence ?? 0, 0.55, accuracy: 0.0001)
    }

    func testAfternoonWithNoKeywordStaysQuiet() {
        let e = engine(
            time: .afternoon,
            reachable: 2,
            hour: 14,
            candidates: [
                SuggestionCandidate(sceneName: "Morning"),
                SuggestionCandidate(sceneName: "Evening"),
                SuggestionCandidate(sceneName: "Sleep")
            ]
        )
        // Only the devices factor (0.10) applies — below the 0.2 surface threshold.
        XCTAssertNil(e.topSuggestion())
    }

    // MARK: - Habit / history

    func testHistoryPromotesHabitualSceneOverGenericMatch() {
        let e = engine(
            time: .evening,
            reachable: 0,
            hour: 20,
            candidates: [
                SuggestionCandidate(sceneName: "Evening"),                       // keyword only
                SuggestionCandidate(sceneName: "Movie Night", runsByHour: [20: 4]) // keyword + strong habit
            ]
        )
        let top = e.topSuggestion()
        XCTAssertEqual(top?.sceneName, "Movie Night")
        XCTAssertEqual(top?.habitRuns, 4)
        // keyword 0.45 + habit capped 0.4
        XCTAssertEqual(top?.confidence ?? 0, 0.85, accuracy: 0.0001)
    }

    func testHabitWindowWrapsAroundMidnight() {
        // At 00:00 the ±1h window is [23, 0, 1]; a run logged at 23:00 must count.
        let e = engine(
            time: .night,
            reachable: 0,
            hour: 0,
            candidates: [SuggestionCandidate(sceneName: "Reading", runsByHour: [23: 3])]
        )
        let top = e.topSuggestion()
        XCTAssertEqual(top?.sceneName, "Reading")
        XCTAssertEqual(top?.habitRuns, 3)
        XCTAssertEqual(top?.confidence ?? 0, 0.36, accuracy: 0.0001) // 0.12 * 3
    }

    func testRunsOutsideWindowAreIgnored() {
        let e = engine(
            time: .night,
            reachable: 0,
            hour: 12,
            candidates: [SuggestionCandidate(sceneName: "Reading", runsByHour: [23: 3])]
        )
        // No keyword, no in-window history → nothing surfaces.
        XCTAssertNil(e.topSuggestion())
    }

    // MARK: - Presence

    func testAwayPresenceBoostsDepartureScene() {
        let e = engine(
            time: .night,
            presence: .away,
            reachable: 0,
            hour: 22,
            candidates: [SuggestionCandidate(sceneName: "Away", geofenceTrigger: .onDeparture)]
        )
        let top = e.topSuggestion()
        XCTAssertEqual(top?.sceneName, "Away")
        XCTAssertEqual(top?.confidence ?? 0, 0.3, accuracy: 0.0001)
        XCTAssertTrue(top?.factors.contains(where: { $0.id == "presence" }) ?? false)
    }

    func testHomePresenceDoesNotBoostDepartureScene() {
        let e = engine(
            time: .night,
            presence: .home,
            reachable: 0,
            hour: 22,
            candidates: [SuggestionCandidate(sceneName: "Away", geofenceTrigger: .onDeparture)]
        )
        XCTAssertNil(e.topSuggestion())
    }

    // MARK: - Favorite

    func testFavoriteBreaksTieBetweenKeywordScenes() {
        let e = engine(
            time: .evening,
            reachable: 0,
            candidates: [
                SuggestionCandidate(sceneName: "Sunset"),
                SuggestionCandidate(sceneName: "Evening", isFavorite: true)
            ]
        )
        // Both match the evening keyword (0.45); the favorite boost (0.1) wins.
        XCTAssertEqual(e.topSuggestion()?.sceneName, "Evening")
    }

    // MARK: - Confidence bounds

    func testConfidenceCappedAtOne() {
        let e = engine(
            time: .evening,
            reachable: 3,
            hour: 20,
            candidates: [
                SuggestionCandidate(sceneName: "Movie Night", isFavorite: true, runsByHour: [20: 5])
            ]
        )
        // 0.45 + 0.4 + 0.1 + 0.1 = 1.05, clamped to 1.0
        XCTAssertEqual(e.topSuggestion()?.confidence ?? 0, 1.0, accuracy: 0.0001)
    }

    // MARK: - Ranking / determinism

    func testRankedSuggestionsBreakTiesByName() {
        let e = engine(
            time: .evening,
            reachable: 0,
            candidates: [
                SuggestionCandidate(sceneName: "Movie Night"),
                SuggestionCandidate(sceneName: "Evening")
            ]
        )
        let ranked = e.rankedSuggestions()
        XCTAssertEqual(ranked.map(\.sceneName), ["Evening", "Movie Night"])
    }

    func testEmptyCandidatesProduceNoSuggestion() {
        let e = engine(candidates: [])
        XCTAssertNil(e.topSuggestion())
        XCTAssertTrue(e.rankedSuggestions().isEmpty)
    }

    // MARK: - Explainability

    func testFactorsAreExposedForEveryScoredScene() {
        let e = engine(
            time: .evening,
            reachable: 2,
            candidates: [SuggestionCandidate(sceneName: "Evening")]
        )
        let top = e.topSuggestion()
        XCTAssertTrue(top?.factors.contains(where: { $0.id == "time" }) ?? false)
        XCTAssertTrue(top?.factors.contains(where: { $0.id == "devices" }) ?? false)
    }
}
