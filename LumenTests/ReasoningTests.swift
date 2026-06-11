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
}
