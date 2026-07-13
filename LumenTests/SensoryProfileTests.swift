import XCTest
@testable import Lumen

final class SensoryProfileTests: XCTestCase {

    func testStandardProfileUsesBalancedDefaults() {
        let profile = SensoryProfile.standard

        XCTAssertFalse(profile.calmModeEnabled)
        XCTAssertEqual(profile.summaryTitle, "Balanced")
        XCTAssertEqual(profile.suggestionCadence, .balanced)
        XCTAssertEqual(profile.motionPreference, .balanced)
        XCTAssertEqual(profile.contrastPreference, .balanced)
        XCTAssertEqual(profile.transitionWarningLabel, "10 min")
        XCTAssertFalse(profile.shouldReduceMotion)
    }

    func testCalmModeDefaultsReduceSensoryLoad() {
        var profile = SensoryProfile.standard

        profile.applyCalmModeDefaults()

        XCTAssertTrue(profile.calmModeEnabled)
        XCTAssertEqual(profile.summaryTitle, "Calm Mode")
        XCTAssertEqual(profile.suggestionCadence, .quiet)
        XCTAssertEqual(profile.motionPreference, .reduced)
        XCTAssertEqual(profile.contrastPreference, .soft)
        XCTAssertEqual(profile.transitionWarningMinutes, 15)
        XCTAssertTrue(profile.shouldReduceMotion)
    }

    func testQuietCadenceLimitsSuggestions() {
        var profile = SensoryProfile.standard
        profile.suggestionCadence = .quiet

        XCTAssertEqual(profile.dailySuggestionLimit, 2)
    }

    func testSupportiveCadenceHasNoDailyLimit() {
        var profile = SensoryProfile.standard
        profile.suggestionCadence = .supportive

        XCTAssertNil(profile.dailySuggestionLimit)
    }

    func testTransitionWarningsCanBeOff() {
        var profile = SensoryProfile.standard
        profile.transitionWarningMinutes = 0

        XCTAssertEqual(profile.transitionWarningLabel, "Off")
    }

    @MainActor
    func testAppStatePersistsSensoryProfile() {
        let suiteName = "LumenTests.SensoryProfile.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let firstState = AppState(userDefaults: defaults)
        firstState.sensoryProfile.applyCalmModeDefaults()
        firstState.sensoryProfile.transitionWarningMinutes = 20

        let secondState = AppState(userDefaults: defaults)

        XCTAssertEqual(secondState.sensoryProfile.suggestionCadence, .quiet)
        XCTAssertEqual(secondState.sensoryProfile.motionPreference, .reduced)
        XCTAssertEqual(secondState.sensoryProfile.transitionWarningMinutes, 20)
    }
}
