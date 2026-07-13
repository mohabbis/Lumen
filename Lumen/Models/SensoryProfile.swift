import Foundation

// MARK: - Sensory Profile
// Lightweight user preference model for neurodivergent-first presentation.

struct SensoryProfile: Codable, Equatable {
    var calmModeEnabled: Bool
    var suggestionCadence: SensorySuggestionCadence
    var motionPreference: SensoryMotionPreference
    var contrastPreference: SensoryContrastPreference
    var transitionWarningMinutes: Int

    static let standard = SensoryProfile(
        calmModeEnabled: false,
        suggestionCadence: .balanced,
        motionPreference: .balanced,
        contrastPreference: .balanced,
        transitionWarningMinutes: 10
    )

    var summaryTitle: String {
        calmModeEnabled ? "Calm Mode" : "Balanced"
    }

    var transitionWarningLabel: String {
        transitionWarningMinutes == 0 ? "Off" : "\(transitionWarningMinutes) min"
    }

    var shouldReduceMotion: Bool {
        calmModeEnabled || motionPreference == .reduced
    }

    var dailySuggestionLimit: Int? {
        switch suggestionCadence {
        case .quiet:      return 2
        case .balanced:   return 4
        case .supportive: return nil
        }
    }

    mutating func applyCalmModeDefaults() {
        calmModeEnabled = true
        suggestionCadence = .quiet
        motionPreference = .reduced
        contrastPreference = .soft
        transitionWarningMinutes = max(transitionWarningMinutes, 15)
    }
}

enum SensorySuggestionCadence: String, CaseIterable, Codable, Identifiable {
    case quiet
    case balanced
    case supportive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quiet:      return "Quiet"
        case .balanced:   return "Balanced"
        case .supportive: return "Supportive"
        }
    }
}

enum SensoryMotionPreference: String, CaseIterable, Codable, Identifiable {
    case reduced
    case balanced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .reduced:  return "Reduced"
        case .balanced: return "Balanced"
        }
    }
}

enum SensoryContrastPreference: String, CaseIterable, Codable, Identifiable {
    case soft
    case balanced
    case clear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .soft:     return "Soft"
        case .balanced: return "Balanced"
        case .clear:    return "Clear"
        }
    }
}
