import Foundation
import SwiftUI

// MARK: - Capability Identity

struct CapabilityID: Hashable, Sendable, CustomStringConvertible {
    let rawValue: String
    init(_ value: String) { rawValue = value }
    var description: String { rawValue }

    static let onOff             = CapabilityID("onOff")
    static let brightness        = CapabilityID("brightness")
    static let colorTemperature  = CapabilityID("colorTemperature")
    static let colorHue          = CapabilityID("colorHue")
    static let temperature       = CapabilityID("temperature")
    static let humidity          = CapabilityID("humidity")
    static let motion            = CapabilityID("motion")
    static let contact           = CapabilityID("contact")
    static let lock              = CapabilityID("lock")
    static let fanSpeed          = CapabilityID("fanSpeed")
    static let targetTemperature = CapabilityID("targetTemperature")
    static let position          = CapabilityID("position")
    static let energyMonitoring  = CapabilityID("energyMonitoring")
    static let airQuality        = CapabilityID("airQuality")
    static let carbonDioxide     = CapabilityID("carbonDioxide")
    static let smoke             = CapabilityID("smoke")
}

// MARK: - Base Capability

protocol DeviceCapability: Sendable {
    var capabilityID: CapabilityID { get }
    var displayName: String { get }
    var isReadOnly: Bool { get }
}

// MARK: - Control Capabilities

protocol OnOffCapability: DeviceCapability {
    var isOn: Bool { get async }
    func setPower(_ on: Bool) async throws
    func toggle() async throws
}

protocol BrightnessCapability: DeviceCapability {
    var brightness: Double { get async }          // 0.0–1.0
    var brightnessRange: ClosedRange<Double> { get }
    func setBrightness(_ value: Double) async throws
}

protocol ColorTemperatureCapability: DeviceCapability {
    var colorTemperature: Int { get async }        // Kelvin
    var temperatureRange: ClosedRange<Int> { get } // e.g. 2700...6500
    func setColorTemperature(_ kelvin: Int) async throws
}

protocol ColorHueCapability: DeviceCapability {
    var hue: Double { get async }                  // 0.0–1.0 (mapped from 0–360°)
    var saturation: Double { get async }           // 0.0–1.0
    func setColor(hue: Double, saturation: Double) async throws
}

protocol LockCapability: DeviceCapability {
    var lockState: LockState { get async }
    func setLock(_ state: LockState) async throws
}

protocol PositionCapability: DeviceCapability {
    var position: Double { get async }             // 0.0 = closed, 1.0 = fully open
    var positionRange: ClosedRange<Double> { get }
    func setPosition(_ value: Double) async throws
}

protocol FanSpeedCapability: DeviceCapability {
    var speed: Double { get async }                // 0.0–1.0
    var availableSpeeds: [Double] { get }
    func setSpeed(_ value: Double) async throws
}

protocol TargetTemperatureCapability: DeviceCapability {
    var targetTemperature: Measurement<UnitTemperature> { get async }
    var temperatureRange: ClosedRange<Measurement<UnitTemperature>> { get }
    var hvacMode: HVACMode { get async }
    func setTargetTemperature(_ temp: Measurement<UnitTemperature>) async throws
    func setHVACMode(_ mode: HVACMode) async throws
}

// MARK: - Sensor Capabilities

protocol TemperatureSensorCapability: DeviceCapability {
    var currentTemperature: Measurement<UnitTemperature> { get async }
    var temperatureStream: AsyncStream<Measurement<UnitTemperature>> { get }
}

protocol HumiditySensorCapability: DeviceCapability {
    var relativeHumidity: Double { get async }     // 0.0–1.0
    var humidityStream: AsyncStream<Double> { get }
}

protocol MotionCapability: DeviceCapability {
    var motionDetected: Bool { get async }
    var lastMotionDate: Date? { get async }
    var motionStream: AsyncStream<Bool> { get }
}

protocol ContactCapability: DeviceCapability {
    var contactState: ContactState { get async }
    var contactStream: AsyncStream<ContactState> { get }
}

protocol AirQualityCapability: DeviceCapability {
    var airQualityIndex: Double { get async }      // 0.0–1.0, where 1.0 = excellent
    var pm25: Double? { get async }                // µg/m³
    var voc: Double? { get async }
    var airQualityStream: AsyncStream<Double> { get }
}

protocol EnergyMonitoringCapability: DeviceCapability {
    var currentWatts: Double { get async }
    var todayKWh: Double? { get async }
    var monthKWh: Double? { get async }
    var energyStream: AsyncStream<Double> { get }
}

protocol SmokeDetectionCapability: DeviceCapability {
    var smokeDetected: Bool { get async }
    var smokeStream: AsyncStream<Bool> { get }
}

// MARK: - Supporting Value Types

enum LockState: String, Sendable, CaseIterable {
    case locked, unlocked, jammed, unknown

    var displayName: String {
        switch self {
        case .locked:   return "Locked"
        case .unlocked: return "Unlocked"
        case .jammed:   return "Jammed"
        case .unknown:  return "Unknown"
        }
    }

    var systemImage: String {
        switch self {
        case .locked:   return "lock.fill"
        case .unlocked: return "lock.open.fill"
        case .jammed:   return "exclamationmark.lock.fill"
        case .unknown:  return "lock.slash.fill"
        }
    }
}

enum HVACMode: String, Sendable, CaseIterable {
    case off, heat, cool, auto, fan

    var displayName: String {
        switch self {
        case .off:  return "Off"
        case .heat: return "Heat"
        case .cool: return "Cool"
        case .auto: return "Auto"
        case .fan:  return "Fan Only"
        }
    }

    var systemImage: String {
        switch self {
        case .off:  return "poweroff"
        case .heat: return "flame.fill"
        case .cool: return "snowflake"
        case .auto: return "thermometer.variable.and.figure"
        case .fan:  return "fan"
        }
    }
}

enum ContactState: String, Sendable {
    case open, closed, unknown
}
