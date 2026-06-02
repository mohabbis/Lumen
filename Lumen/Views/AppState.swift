import SwiftUI
import Observation

// MARK: - App State
// UI-only state. No SwiftData model references — those live in services.

@MainActor
@Observable
final class AppState {
    var selectedTab: Tab = .home
    var isShowingOnboarding: Bool = false
    var enableLocalPreviewControls: Bool = true
    var showDebugDetails: Bool = false
    var hapticFeedbackEnabled: Bool = true

    enum Tab: String, CaseIterable, Hashable {
        case home     = "Home"
        case rooms    = "Rooms"
        case intel    = "Intel"
        case auto     = "Auto"
        case settings = "Settings"

        var label: String { rawValue }

        var systemImage: String {
            switch self {
            case .home:     return "house.fill"
            case .rooms:    return "door.left.hand.open"
            case .intel:    return "sparkle"
            case .auto:     return "sparkles"
            case .settings: return "gearshape.fill"
            }
        }
    }
}
