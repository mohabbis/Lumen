//
//  DeviceType.swift
//  Muhome
//
//  Created by Muhammad Rafiq on 20/05/2026.
//

import SwiftUI

// MARK: - Device Type (Planning)
enum DeviceType: String, CaseIterable, Codable {
    // Lighting
    case light = "Light"
    case switchDevice = "Switch"
    case dimmer = "Dimmer"
    
    // Climate
    case thermostat = "Thermostat"
    case airPurifier = "Air Purifier"
    case fan = "Fan"
    
    // Security
    case doorLock = "Door Lock"
    case motionSensor = "Motion Sensor"
    case contactSensor = "Contact Sensor"
    case camera = "Camera"
    
    // Window Coverings
    case windowCover = "Window Cover"
    
    // Sensors
    case temperatureSensor = "Temperature Sensor"
    case humiditySensor = "Humidity Sensor"
    
    // Entertainment
    case speaker = "Speaker"
    case tv = "TV"
    case streamingBox = "Streaming Box"
    case vacuum = "Vacuum"
    
    var iconName: String {
        switch self {
        case .light: return "lightbulb.fill"
        case .switchDevice: return "powerplug.fill"
        case .dimmer: return "sun.min"
        case .thermostat: return "thermometer"
        case .doorLock: return "lock.fill"
        case .windowCover: return "window"
        case .motionSensor: return "motion.sensor"
        case .contactSensor: return "sensor.tag"
        case .temperatureSensor: return "thermometer"
        case .humiditySensor: return "humidity"
        case .airPurifier: return "fan"
        case .fan: return "fan"
        case .vacuum: return "vacuum"
        case .camera: return "camera.fill"
        case .speaker: return "speaker.wave"
        case .tv: return "tv"
        case .streamingBox: return "appletv"
        }
    }
    
    var displayName: String {
        switch self {
        case .switchDevice: return "Switch"
        default: return rawValue
        }
    }
}