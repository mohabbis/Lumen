import Foundation
import SwiftUI
import Observation

// MARK: - App State
// UI-only state. No SwiftData model references — those live in services.

@MainActor
@Observable
final class AppState {
    @ObservationIgnored private static let sensoryProfileDefaultsKey = "lumen.sensoryProfile.v1"
    @ObservationIgnored private let userDefaults: UserDefaults

    var selectedTab: Tab = .home
    var isShowingOnboarding: Bool = false
    var enableLocalPreviewControls: Bool = true
    var showDebugDetails: Bool = false
    var hapticFeedbackEnabled: Bool = true
    var sensoryProfile: SensoryProfile {
        didSet { saveSensoryProfile() }
    }
    var suggestionsPaused: Bool = false

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.sensoryProfile = Self.loadSensoryProfile(from: userDefaults)
    }

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

    private static func loadSensoryProfile(from userDefaults: UserDefaults) -> SensoryProfile {
        guard
            let data = userDefaults.data(forKey: sensoryProfileDefaultsKey),
            let profile = try? JSONDecoder().decode(SensoryProfile.self, from: data)
        else {
            return .standard
        }
        return profile
    }

    private func saveSensoryProfile() {
        guard let data = try? JSONEncoder().encode(sensoryProfile) else { return }
        userDefaults.set(data, forKey: Self.sensoryProfileDefaultsKey)
    }
}
