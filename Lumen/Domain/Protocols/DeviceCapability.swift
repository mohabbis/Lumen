import Foundation

// MARK: - Capability Identity

struct CapabilityID: Hashable, Sendable, CustomStringConvertible {
    let rawValue: String
    init(_ value: String) { rawValue = value }
    var description: String { rawValue }

    static let onOff              = CapabilityID("onOff")
    static let brightness         = CapabilityID("brightness")
    static let colorTemperature   = CapabilityID("colorTemperature")
    static let colorHue           = CapabilityID("colorHue")
    static let lock               = CapabilityID("lock")
    static let position           = CapabilityID("position")
    static let targetTemperature  = CapabilityID("targetTemperature")
    static let temperature        = CapabilityID("temperature")
    static let humidity           = CapabilityID("humidity")
    static let motion             = CapabilityID("motion")
    static let contact            = CapabilityID("contact")
}

// MARK: - Domain Enumerations

enum LockState: String, Sendable, Equatable, CaseIterable {
    case locked, unlocked, jammed, unknown
}

enum ContactState: String, Sendable, Equatable {
    case open, closed, unknown
}

enum HVACMode: String, Sendable, Equatable, CaseIterable {
    case off, heat, cool, auto, fan
}

// MARK: - Base Capability Protocol

protocol DeviceCapability: Sendable {
    var capabilityID: CapabilityID { get }
    var displayName: String { get }
    var isReadOnly: Bool { get }
}

// MARK: - Actuator Protocols

protocol OnOffCapability: DeviceCapability {
    var isOn: Bool { get async }
    func setPower(_ on: Bool) async throws
    func toggle() async throws
}

protocol BrightnessCapability: DeviceCapability {
    var brightnessRange: ClosedRange<Double> { get }
    var brightness: Double { get async }
    func setBrightness(_ value: Double) async throws
}

protocol ColorTemperatureCapability: DeviceCapability {
    var temperatureRange: ClosedRange<Int> { get }
    var colorTemperature: Int { get async }
    func setColorTemperature(_ kelvin: Int) async throws
}

protocol ColorHueCapability: DeviceCapability {
    var hue: Double { get async }
    var saturation: Double { get async }
    func setColor(hue: Double, saturation: Double) async throws
}

protocol LockCapability: DeviceCapability {
    var lockState: LockState { get async }
    func setLock(_ state: LockState) async throws
}

protocol PositionCapability: DeviceCapability {
    var positionRange: ClosedRange<Double> { get }
    var position: Double { get async }
    func setPosition(_ value: Double) async throws
}

protocol TargetTemperatureCapability: DeviceCapability {
    var temperatureRange: ClosedRange<Measurement<UnitTemperature>> { get }
    var targetTemperature: Measurement<UnitTemperature> { get async }
    var hvacMode: HVACMode { get async }
    func setTargetTemperature(_ temp: Measurement<UnitTemperature>) async throws
    func setHVACMode(_ mode: HVACMode) async throws
}

// MARK: - Sensor Protocols

protocol TemperatureSensorCapability: DeviceCapability {
    var currentTemperature: Measurement<UnitTemperature> { get async }
    var temperatureStream: AsyncStream<Measurement<UnitTemperature>> { get }
}

protocol HumiditySensorCapability: DeviceCapability {
    var relativeHumidity: Double { get async }
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
