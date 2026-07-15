import UIKit

// MARK: - Lumen Haptics
// Centralized, calm haptic feedback for Lumen's consent moments.
//
// Lumen is consent-before-action: a soft, deliberate tap is what tells you that
// *you* approved something. This enum is the single place that speaks to the
// Taptic Engine, so the feel stays consistent everywhere — a gentle success
// when a scene runs, a selection tick when you favorite one, a soft bump when
// an arrival/departure banner appears.
//
// All feedback is suppressed under XCTest so headless unit runs stay silent and
// never touch UIKit's feedback generators.

@MainActor
enum LumenHaptics {

    /// A scene ran or a suggested action was applied — a gentle success tap.
    static func success() { notify(.success) }

    /// A recoverable hiccup the user should notice.
    static func warning() { notify(.warning) }

    /// An action failed.
    static func error() { notify(.error) }

    /// A discrete value or toggle changed (e.g. favoriting a scene).
    static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }

    /// A light physical bump, e.g. when an ambient status banner appears.
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Haptics are disabled under XCTest so the unit suite stays silent.
    /// Exposed for testing the guard directly.
    static var isEnabled: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil
    }
}
