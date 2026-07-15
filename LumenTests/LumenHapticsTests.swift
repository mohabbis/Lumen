import XCTest
@testable import Lumen

// MARK: - LumenHaptics Tests
// Verifies the XCTest guard so the unit suite never fires real haptics, and
// that every entry point is a safe no-op while disabled.

@MainActor
final class LumenHapticsTests: XCTestCase {

    func testHapticsAreDisabledUnderXCTest() {
        // The unit suite always runs with XCTestConfigurationFilePath set, so
        // the Taptic Engine is never touched during tests.
        XCTAssertFalse(LumenHaptics.isEnabled)
    }

    func testFeedbackEntryPointsAreNoOpWhileDisabled() {
        // Each call should return without touching UIKit's generators.
        LumenHaptics.success()
        LumenHaptics.warning()
        LumenHaptics.error()
        LumenHaptics.selection()
        LumenHaptics.impact()
        LumenHaptics.impact(.soft)
    }
}
