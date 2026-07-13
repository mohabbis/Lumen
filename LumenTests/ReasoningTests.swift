import XCTest
@testable import Lumen

final class ReasoningTests: XCTestCase {

    // MARK: - Headline

    func testHeadlineDiffersPerTimeOfDay() {
        let dawn = ReasoningCalculator(
            timeOfDay: .dawn,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        let night = ReasoningCalculator(
            timeOfDay: .night,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        XCTAssertNotEqual(dawn.headline, night.headline)
    }

    // MARK: - Signals

    func testSignalsAlwaysIncludeTimeAndPresence() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        XCTAssertTrue(r.signals.contains(where: { $0.id == "time" }))
        XCTAssertTrue(r.signals.contains(where: { $0.id == "presence" }))
    }

    func testReachableDevicesSignalHiddenAtZero() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        XCTAssertFalse(r.signals.contains(where: { $0.id == "devices" }))
    }

    func testReachableDevicesSignalShownAboveZero() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 4,
            suggestedSceneName: nil
        ).reasoning

        let signal = r.signals.first(where: { $0.id == "devices" })
        XCTAssertEqual(signal?.value, "4")
    }

    func testSceneSignalHiddenWhenNoSuggestion() {
        let r = ReasoningCalculator(
            timeOfDay: .afternoon,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        XCTAssertFalse(r.signals.contains(where: { $0.id == "scene" }))
    }

    func testSceneSignalShowsMissingExpectedScene() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 2,
            suggestedSceneName: nil,
            expectedSceneName: "Evening"
        ).reasoning

        let signal = r.signals.first(where: { $0.id == "scene" })
        XCTAssertEqual(signal?.value, "Evening not set up")
        XCTAssertEqual(signal?.weight, .low)
    }

    func testSceneSignalShownWithSuggestion() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: "Evening"
        ).reasoning

        let signal = r.signals.first(where: { $0.id == "scene" })
        XCTAssertEqual(signal?.value, "Evening")
    }

    // MARK: - Presence value

    func testPresenceValueIsAtHomeWhenHome() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        let presence = r.signals.first(where: { $0.id == "presence" })
        XCTAssertEqual(presence?.value, "At home")
    }

    func testPresenceValueShowsKmAwayWhenDistanceKnown() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: false,
            distanceToHome: 2_500,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        let presence = r.signals.first(where: { $0.id == "presence" })
        XCTAssertEqual(presence?.value, "2.5 km away")
    }

    func testPresenceValueFallsBackToAwayWithoutDistance() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: false,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        let presence = r.signals.first(where: { $0.id == "presence" })
        XCTAssertEqual(presence?.value, "Away")
    }

    // MARK: - Suggestion label

    func testSuggestionLabelOmittedWhenNoScene() {
        let r = ReasoningCalculator(
            timeOfDay: .afternoon,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: nil
        ).reasoning

        XCTAssertNil(r.suggestionLabel)
    }

    func testSuggestionLabelFormatted() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: "Evening"
        ).reasoning

        XCTAssertEqual(r.suggestionLabel, "Apply Evening")
    }

    // MARK: - Scored-layer signals (SuggestionEngine output)

    func testConfidenceSignalOmittedByDefault() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: "Evening"
        ).reasoning

        XCTAssertFalse(r.signals.contains(where: { $0.id == "confidence" }))
        XCTAssertFalse(r.signals.contains(where: { $0.id == "habit" }))
    }

    func testConfidenceSignalFormattedAsPercent() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: "Evening",
            confidence: 0.55
        ).reasoning

        let signal = r.signals.first(where: { $0.id == "confidence" })
        XCTAssertEqual(signal?.value, "55%")
        XCTAssertEqual(signal?.weight, .medium)
    }

    func testHabitSignalShownWhenRunsPositive() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: "Movie Night",
            habitRuns: 4
        ).reasoning

        let signal = r.signals.first(where: { $0.id == "habit" })
        XCTAssertEqual(signal?.value, "4× around now")
    }

    func testHabitSignalHiddenAtZeroRuns() {
        let r = ReasoningCalculator(
            timeOfDay: .evening,
            isAtHome: true,
            distanceToHome: nil,
            reachableDevices: 0,
            suggestedSceneName: "Evening",
            habitRuns: 0
        ).reasoning

        XCTAssertFalse(r.signals.contains(where: { $0.id == "habit" }))
    }

    // MARK: - Notice presentation

    func testNoticePresentationIsActionableWhenSuggestedSceneExists() {
        let presentation = LumenNoticePresentation(
            timeOfDay: .evening,
            isAtHome: true,
            reachableDevices: 3,
            expectedSceneName: "Evening",
            suggestedSceneName: "Evening"
        )

        XCTAssertTrue(presentation.isActionable)
        XCTAssertEqual(presentation.suggestion, "Review Evening scene")
        XCTAssertEqual(presentation.detail, "Confirm before anything changes")
        XCTAssertEqual(presentation.iconName, "sparkles")
    }

    func testNoticePresentationExplainsMissingExpectedScene() {
        let presentation = LumenNoticePresentation(
            timeOfDay: .evening,
            isAtHome: true,
            reachableDevices: 3,
            expectedSceneName: "Evening",
            suggestedSceneName: nil
        )

        XCTAssertFalse(presentation.isActionable)
        XCTAssertEqual(presentation.suggestion, "Evening scene not set up")
        XCTAssertEqual(presentation.detail, "Signals available, no action queued")
    }

    func testNoticePresentationUsesInformationalStateWhenNoSceneExpected() {
        let presentation = LumenNoticePresentation(
            timeOfDay: .afternoon,
            isAtHome: true,
            reachableDevices: 0,
            expectedSceneName: nil,
            suggestedSceneName: nil
        )

        XCTAssertFalse(presentation.isActionable)
        XCTAssertEqual(presentation.suggestion, "No scene suggested now")
        XCTAssertEqual(presentation.detail, "Review the current signals")
    }

    func testNoticePresentationUsesAwayModeMessage() {
        let presentation = LumenNoticePresentation(
            timeOfDay: .night,
            isAtHome: false,
            reachableDevices: 1,
            expectedSceneName: "Sleep",
            suggestedSceneName: "Sleep"
        )

        XCTAssertEqual(presentation.message, "Away mode is active. Lumen is keeping the home state visible.")
        XCTAssertEqual(presentation.iconName, "location.fill")
    }
}
