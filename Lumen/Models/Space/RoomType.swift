//
//  RoomType.swift
//  Muhome
//
//  Created by Muhammad Rafiq on 20/05/2026.
//

import SwiftUI

// MARK: - Room Type
enum RoomType: String, CaseIterable, Codable {
    case livingRoom = "Living Room"
    case kitchen = "Kitchen"
    case bedroom = "Bedroom"
    case bathroom = "Bathroom"
    case office = "Office"
    case garage = "Garage"
    case basement = "Basement"
    case attic = "Attic"
    case hallway = "Hallway"
    case entryway = "Entryway"
    case outdoor = "Outdoor"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .livingRoom: return "sofa.fill"
        case .kitchen:    return "fork.knife"
        case .bedroom:    return "bed.double.fill"
        case .bathroom:   return "shower.fill"
        case .office:     return "laptopcomputer"
        case .garage:     return "car.fill"
        case .basement:   return "square.3.layers.3d.down.left"
        case .attic:      return "house.lodge.fill"
        case .hallway:    return "figure.walk"
        case .entryway:   return "door.left.hand.open"
        case .outdoor:    return "sun.max.fill"
        case .other:      return "square.dashed"
        }
    }
}

// MARK: - Room Behavior Profile

struct RoomBehaviorProfile {
    let defaultColorTemperature: Int    // Kelvin
    let defaultBrightness: Double       // 0.0–1.0
    let preferredStartHour: Int         // 24h, when the room is typically "active"
    let preferredEndHour: Int           // wraps midnight if start > end
    let quietByDefault: Bool            // low light, minimal automation noise

    func isActiveHour(_ hour: Int) -> Bool {
        if preferredStartHour <= preferredEndHour {
            return (preferredStartHour...preferredEndHour).contains(hour)
        } else {
            // crosses midnight (e.g., bedroom: 21–8)
            return hour >= preferredStartHour || hour <= preferredEndHour
        }
    }
}

extension RoomType {
    var behaviorProfile: RoomBehaviorProfile {
        switch self {
        case .bedroom:    return .init(defaultColorTemperature: 2700, defaultBrightness: 0.3,  preferredStartHour: 21, preferredEndHour: 8,  quietByDefault: true)
        case .office:     return .init(defaultColorTemperature: 5500, defaultBrightness: 0.9,  preferredStartHour: 8,  preferredEndHour: 18, quietByDefault: false)
        case .livingRoom: return .init(defaultColorTemperature: 3000, defaultBrightness: 0.7,  preferredStartHour: 8,  preferredEndHour: 23, quietByDefault: false)
        case .kitchen:    return .init(defaultColorTemperature: 4000, defaultBrightness: 1.0,  preferredStartHour: 6,  preferredEndHour: 22, quietByDefault: false)
        case .bathroom:   return .init(defaultColorTemperature: 4500, defaultBrightness: 0.8,  preferredStartHour: 5,  preferredEndHour: 23, quietByDefault: false)
        case .hallway:    return .init(defaultColorTemperature: 3500, defaultBrightness: 0.6,  preferredStartHour: 0,  preferredEndHour: 23, quietByDefault: false)
        case .entryway:   return .init(defaultColorTemperature: 3500, defaultBrightness: 0.8,  preferredStartHour: 6,  preferredEndHour: 23, quietByDefault: false)
        case .garage:     return .init(defaultColorTemperature: 4000, defaultBrightness: 1.0,  preferredStartHour: 6,  preferredEndHour: 22, quietByDefault: false)
        case .basement:   return .init(defaultColorTemperature: 3500, defaultBrightness: 0.8,  preferredStartHour: 8,  preferredEndHour: 22, quietByDefault: false)
        case .attic:      return .init(defaultColorTemperature: 4000, defaultBrightness: 1.0,  preferredStartHour: 8,  preferredEndHour: 20, quietByDefault: false)
        case .outdoor:    return .init(defaultColorTemperature: 3000, defaultBrightness: 0.5,  preferredStartHour: 18, preferredEndHour: 23, quietByDefault: false)
        case .other:      return .init(defaultColorTemperature: 3500, defaultBrightness: 0.7,  preferredStartHour: 0,  preferredEndHour: 23, quietByDefault: false)
        }
    }
}