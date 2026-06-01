//
//  SceneModels.swift
//  Muhome
//
//  Created by Muhammad Rafiq on 19/05/2026.
//  Copyright © 2026 Muhome. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Scene Color Swatch

enum SceneColorSwatch: String, Codable, CaseIterable, Sendable {
    case goldenHour   // warm amber ~2700K
    case afternoon    // neutral ~3500K
    case daylight     // cool white ~5500K
    case evening      // soft warm ~2200K
    case night        // deep amber ~1800K
    case vibrant      // full color
    case monochrome   // white only

    var kelvin: Double {
        switch self {
        case .goldenHour: return 2700
        case .afternoon:  return 3500
        case .daylight:   return 5500
        case .evening:    return 2200
        case .night:      return 1800
        case .vibrant:    return 3000
        case .monochrome: return 4000
        }
    }

    var previewColor: Color {
        switch self {
        case .goldenHour: return Color(hue: 0.09, saturation: 0.70, brightness: 0.95)
        case .afternoon:  return Color(hue: 0.10, saturation: 0.35, brightness: 0.97)
        case .daylight:   return Color(hue: 0.12, saturation: 0.10, brightness: 1.00)
        case .evening:    return Color(hue: 0.07, saturation: 0.80, brightness: 0.88)
        case .night:      return Color(hue: 0.05, saturation: 0.90, brightness: 0.75)
        case .vibrant:    return Color(hue: 0.60, saturation: 0.80, brightness: 0.90)
        case .monochrome: return Color(white: 0.92)
        }
    }

    var displayName: String {
        switch self {
        case .goldenHour: return "Golden Hour"
        case .afternoon:  return "Afternoon"
        case .daylight:   return "Daylight"
        case .evening:    return "Evening"
        case .night:      return "Night"
        case .vibrant:    return "Vibrant"
        case .monochrome: return "White"
        }
    }
}

// MARK: - Scene Action

struct MuhaSceneAction: Codable, Sendable {
    let deviceId: String
    let action: String
    let delaySeconds: Double

    init(deviceId: String, action: String, delaySeconds: Double = 0) {
        self.deviceId = deviceId
        self.action = action
        self.delaySeconds = delaySeconds
    }
}

// MARK: - MuhaScene

struct MuhaScene: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var iconName: String
    var colorSwatch: SceneColorSwatch
    var actions: [MuhaSceneAction]
    var isDefault: Bool
    var sortOrder: Int
    var lastActivated: Date?
    var activationCount: Int

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorSwatch: SceneColorSwatch,
        actions: [MuhaSceneAction] = [],
        isDefault: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorSwatch = colorSwatch
        self.actions = actions
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.activationCount = 0
    }
}

// MARK: - Hex Color Helper

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
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
        default:
            red = 0
            green = 0
            blue = 0
        }

        self.init(red: red, green: green, blue: blue)
    }
}

// MARK: - Default Scenes

extension MuhaScene {
    static let defaultScenes: [MuhaScene] = [
        MuhaScene(
            name: "Morning",
            iconName: "sunrise.fill",
            colorSwatch: .goldenHour,
            isDefault: true,
            sortOrder: 0
        ),
        MuhaScene(
            name: "Evening",
            iconName: "moon.stars.fill",
            colorSwatch: .evening,
            isDefault: true,
            sortOrder: 1
        ),
        MuhaScene(
            name: "Movie Night",
            iconName: "popcorn.fill",
            colorSwatch: .night,
            isDefault: true,
            sortOrder: 2
        ),
        MuhaScene(
            name: "Sleep",
            iconName: "zzz",
            colorSwatch: .night,
            isDefault: true,
            sortOrder: 3
        ),
        MuhaScene(
            name: "Away",
            iconName: "house.slash.fill",
            colorSwatch: .monochrome,
            isDefault: true,
            sortOrder: 4
        ),
    ]
}

// MARK: - Time of Day

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
        case .dawn:
            return [Color(hex: "#1A0F35"), Color(hex: "#0E0819")]
        case .morning:
            return [Color(hex: "#0F1530"), Color(hex: "#0E0819")]
        case .afternoon:
            return [Color(hex: "#0D1228"), Color(hex: "#0E0819")]
        case .evening:
            return [Color(hex: "#1E0F38"), Color(hex: "#0E0819")]
        case .night:
            return [Color(hex: "#080618"), Color(hex: "#0E0819")]
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
        case .morning, .afternoon: return false
        }
    }
}
