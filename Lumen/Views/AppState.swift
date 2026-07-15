import Foundation
import SwiftUI
import Observation

// MARK: - App State
// UI-only state. No SwiftData model references — those live in services.

@MainActor
@Observable
final class AppState {
    @ObservationIgnored private static let sensoryProfileDefaultsKey = "lumen.sensoryProfile.v1"
    @ObservationIgnored private static let suggestionCountKey = "lumen.suggestionCount.v1"
    @ObservationIgnored private static let lastSuggestionDateKey = "lumen.lastSuggestionDate.v1"
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
    
    /// Tracks how many suggestions have been shown today (respects sensory profile limits)
    var todaysSuggestionCount: Int {
        didSet { saveSuggestionTracking() }
    }
    
    /// Last date a suggestion was shown (for daily reset)
    var lastSuggestionDate: Date? {
        didSet { saveSuggestionTracking() }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.sensoryProfile = Self.loadSensoryProfile(from: userDefaults)
        self.todaysSuggestionCount = Self.loadTodaysSuggestionCount(from: userDefaults)
        self.lastSuggestionDate = Self.loadLastSuggestionDate(from: userDefaults)
        Self.resetSuggestionCountIfNeeded(userDefaults: userDefaults)
    }
    
    /// Check if daily limit has been reached based on sensory profile
    var hasReachedDailySuggestionLimit: Bool {
        guard let limit = sensoryProfile.dailySuggestionLimit else { return false }
        return todaysSuggestionCount >= limit
    }
    
    /// Increment suggestion count and reset if new day
    func recordSuggestionShown() {
        Self.resetSuggestionCountIfNeeded(userDefaults: userDefaults)
        todaysSuggestionCount += 1
        lastSuggestionDate = Date()
    }
    
    /// Reset suggestion count for new day
    private static func resetSuggestionCountIfNeeded(userDefaults: UserDefaults) {
        guard let lastDate = loadLastSuggestionDate(from: userDefaults) else { return }
        
        let calendar = Calendar.current
        if !calendar.isDateInToday(lastDate) {
            userDefaults.set(0, forKey: suggestionCountKey)
            userDefaults.set(Date(), forKey: lastSuggestionDateKey)
        }
    }
    
    private static func loadTodaysSuggestionCount(from userDefaults: UserDefaults) -> Int {
        return userDefaults.integer(forKey: suggestionCountKey)
    }
    
    private static func loadLastSuggestionDate(from userDefaults: UserDefaults) -> Date? {
        guard let data = userDefaults.data(forKey: lastSuggestionDateKey) else { return nil }
        return try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? Date
    }
    
    private func saveSuggestionTracking() {
        userDefaults.set(todaysSuggestionCount, forKey: Self.suggestionCountKey)
        if let date = lastSuggestionDate {
            let data = try? NSKeyedArchiver.archivedData(withRootObject: date, requiringSecureCoding: false)
            userDefaults.set(data, forKey: Self.lastSuggestionDateKey)
        }
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
