import Foundation
import SwiftUI

// MARK: - Time of Day
// The ambient time-block model used by the dashboard, the rhythm card,
// and the reasoning surface.

enum TimeOfDay: Equatable {
    case dawn      // 5–7
    case morning   // 7–12
    case afternoon // 12–17
    case evening   // 17–21
    case night     // 21–5

    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<7:   return .dawn
        case 7..<12:  return .morning
        case 12..<17: return .afternoon
        case 17..<21: return .evening
        default:      return .night
        }
    }

    var greeting: String {
        switch self {
        case .dawn:      return "Good morning"
        case .morning:   return "Good morning"
        case .afternoon: return "Good afternoon"
        case .evening:   return "Good evening"
        case .night:     return "Good night"
        }
    }

    var backgroundColors: [Color] {
        switch self {
        case .dawn:      return [Color(hex: "#1A0F35"), Color(hex: "#0E0819")]
        case .morning:   return [Color(hex: "#0F1530"), Color(hex: "#0E0819")]
        case .afternoon: return [Color(hex: "#0D1228"), Color(hex: "#0E0819")]
        case .evening:   return [Color(hex: "#1E0F38"), Color(hex: "#0E0819")]
        case .night:     return [Color(hex: "#080618"), Color(hex: "#0E0819")]
        }
    }

    var accentColor: Color {
        switch self {
        case .dawn:      return Color(hex: "#D4825A")
        case .morning:   return Color(hex: "#C4956A")
        case .afternoon: return Color(hex: "#B8A08A")
        case .evening:   return Color(hex: "#D4825A")
        case .night:     return Color(hex: "#8B5E3C")
        }
    }

    var isDark: Bool {
        switch self {
        case .evening, .night, .dawn: return true
        case .morning, .afternoon:    return false
        }
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red: Double
        let green: Double
        let blue: Double
        switch cleaned.count {
        case 6:
            red   = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8)  / 255
            blue  = Double( value & 0x0000FF)        / 255
        default:
            red = 0; green = 0; blue = 0
        }

        self.init(red: red, green: green, blue: blue)
    }
}
