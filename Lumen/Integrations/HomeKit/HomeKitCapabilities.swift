import Foundation
import HomeKit

extension HMService {
    func characteristic(ofType type: String) -> HMCharacteristic? {
        characteristics.first { $0.characteristicType == type }
    }
}

// MARK: - HomeKit Capability Implementations
// Each struct wraps HMService characteristics and conforms to the capability protocol.
// HMAccessory / HMService references are kept private — never exposed to callers.

// MARK: - On/Off

struct HomeKitOnOffCapability: OnOffCapability {
    let capabilityID: CapabilityID = .onOff
    let displayName = "Power"
    let isReadOnly = false

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var isOn: Bool {
        get async {
            service.characteristic(ofType: HMCharacteristicTypePowerState)?.value as? Bool ?? false
        }
    }

    func setPower(_ on: Bool) async throws {
        try await requireChar(HMCharacteristicTypePowerState).writeValue(on)
    }

    func toggle() async throws {
        try await setPower(!(await isOn))
    }

    private func requireChar(_ type: String) throws -> HMCharacteristic {
        guard let c = service.characteristic(ofType: type) else {
            throw AppError.capabilityNotSupported(capabilityID, deviceID: accessory.uniqueIdentifier)
        }
        return c
    }
}

// MARK: - Brightness

struct HomeKitBrightnessCapability: BrightnessCapability {
    let capabilityID: CapabilityID = .brightness
    let displayName = "Brightness"
    let isReadOnly = false
    let brightnessRange: ClosedRange<Double> = 0.0...1.0

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var brightness: Double {
        get async {
            let raw = service.characteristic(ofType: HMCharacteristicTypeBrightness)?.value as? Int ?? 0
            return Double(raw) / 100.0
        }
    }

    func setBrightness(_ value: Double) async throws {
        let clamped = value.clamped(to: 0.0...1.0)
        guard let char = service.characteristic(ofType: HMCharacteristicTypeBrightness) else {
            throw AppError.capabilityNotSupported(capabilityID, deviceID: accessory.uniqueIdentifier)
        }
        try await char.writeValue(Int(clamped * 100))
    }
}

// MARK: - Color Temperature

struct HomeKitColorTemperatureCapability: ColorTemperatureCapability {
    let capabilityID: CapabilityID = .colorTemperature
    let displayName = "Color Temperature"
    let isReadOnly = false
    let temperatureRange: ClosedRange<Int> = 2700...6500

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var colorTemperature: Int {
        get async {
            let mireds = service.characteristic(ofType: HMCharacteristicTypeColorTemperature)?.value as? Int ?? 370
            return mireds > 0 ? 1_000_000 / mireds : 2700
        }
    }

    func setColorTemperature(_ kelvin: Int) async throws {
        let clamped = kelvin.clamped(to: temperatureRange)
        let mireds = 1_000_000 / clamped
        guard let char = service.characteristic(ofType: HMCharacteristicTypeColorTemperature) else {
            throw AppError.capabilityNotSupported(capabilityID, deviceID: accessory.uniqueIdentifier)
        }
        try await char.writeValue(mireds)
    }
}

// MARK: - Color Hue

struct HomeKitColorHueCapability: ColorHueCapability {
    let capabilityID: CapabilityID = .colorHue
    let displayName = "Color"
    let isReadOnly = false

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var hue: Double {
        get async {
            (service.characteristic(ofType: HMCharacteristicTypeHue)?.value as? Double ?? 0) / 360.0
        }
    }

    var saturation: Double {
        get async {
            (service.characteristic(ofType: HMCharacteristicTypeSaturation)?.value as? Double ?? 0) / 100.0
        }
    }

    func setColor(hue: Double, saturation: Double) async throws {
        async let hueResult: Void = {
            guard let c = service.characteristic(ofType: HMCharacteristicTypeHue) else { return }
            try await c.writeValue(hue * 360.0)
        }()
        async let satResult: Void = {
            guard let c = service.characteristic(ofType: HMCharacteristicTypeSaturation) else { return }
            try await c.writeValue(saturation * 100.0)
        }()
        _ = try await (hueResult, satResult)
    }
}

// MARK: - Lock

struct HomeKitLockCapability: LockCapability {
    let capabilityID: CapabilityID = .lock
    let displayName = "Lock"
    let isReadOnly = false

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var lockState: LockState {
        get async {
            switch service.characteristic(ofType: HMCharacteristicTypeCurrentLockMechanismState)?.value as? UInt {
            case 0:  return .unlocked
            case 1:  return .locked
            case 2:  return .jammed
            default: return .unknown
            }
        }
    }

    func setLock(_ state: LockState) async throws {
        guard let char = service.characteristic(ofType: HMCharacteristicTypeTargetLockMechanismState) else {
            throw AppError.capabilityNotSupported(capabilityID, deviceID: accessory.uniqueIdentifier)
        }
        try await char.writeValue(state == .locked ? UInt(1) : UInt(0))
    }
}

// MARK: - Position (Window Coverings)

struct HomeKitPositionCapability: PositionCapability {
    let capabilityID: CapabilityID = .position
    let displayName = "Position"
    let isReadOnly = false
    let positionRange: ClosedRange<Double> = 0.0...1.0

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var position: Double {
        get async {
            let raw = service.characteristic(ofType: HMCharacteristicTypeCurrentPosition)?.value as? Int ?? 0
            return Double(raw) / 100.0
        }
    }

    func setPosition(_ value: Double) async throws {
        guard let char = service.characteristic(ofType: HMCharacteristicTypeTargetPosition) else {
            throw AppError.capabilityNotSupported(capabilityID, deviceID: accessory.uniqueIdentifier)
        }
        try await char.writeValue(Int(value.clamped(to: 0.0...1.0) * 100))
    }
}

// MARK: - Target Temperature (Thermostat)

struct HomeKitTargetTemperatureCapability: TargetTemperatureCapability {
    let capabilityID: CapabilityID = .targetTemperature
    let displayName = "Temperature"
    let isReadOnly = false
    let temperatureRange: ClosedRange<Measurement<UnitTemperature>> =
        Measurement(value: 10, unit: .celsius)...Measurement(value: 38, unit: .celsius)

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var targetTemperature: Measurement<UnitTemperature> {
        get async {
            let c = service.characteristic(ofType: HMCharacteristicTypeTargetTemperature)?.value as? Double ?? 20
            return Measurement(value: c, unit: .celsius)
        }
    }

    var hvacMode: HVACMode {
        get async {
            switch service.characteristic(ofType: HMCharacteristicTypeTargetHeatingCooling)?.value as? Int {
            case 0:  return .off
            case 1:  return .heat
            case 2:  return .cool
            case 3:  return .auto
            default: return .auto
            }
        }
    }

    func setTargetTemperature(_ temp: Measurement<UnitTemperature>) async throws {
        guard let char = service.characteristic(ofType: HMCharacteristicTypeTargetTemperature) else {
            throw AppError.capabilityNotSupported(capabilityID, deviceID: accessory.uniqueIdentifier)
        }
        try await char.writeValue(temp.converted(to: .celsius).value)
    }

    func setHVACMode(_ mode: HVACMode) async throws {
        guard let char = service.characteristic(ofType: HMCharacteristicTypeTargetHeatingCooling) else {
            throw AppError.capabilityNotSupported(capabilityID, deviceID: accessory.uniqueIdentifier)
        }
        let raw: Int
        switch mode {
        case .off:  raw = 0
        case .heat: raw = 1
        case .cool: raw = 2
        case .auto, .fan: raw = 3
        }
        try await char.writeValue(raw)
    }
}

// MARK: - Temperature Sensor

struct HomeKitTemperatureSensorCapability: TemperatureSensorCapability {
    let capabilityID: CapabilityID = .temperature
    let displayName = "Temperature"
    let isReadOnly = true

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var currentTemperature: Measurement<UnitTemperature> {
        get async {
            let c = service.characteristic(ofType: HMCharacteristicTypeCurrentTemperature)?.value as? Double ?? 0
            return Measurement(value: c, unit: .celsius)
        }
    }

    var temperatureStream: AsyncStream<Measurement<UnitTemperature>> {
        AsyncStream { _ in }  // Full push via HMCharacteristic.enableNotification — Phase 2
    }
}

// MARK: - Humidity Sensor

struct HomeKitHumiditySensorCapability: HumiditySensorCapability {
    let capabilityID: CapabilityID = .humidity
    let displayName = "Humidity"
    let isReadOnly = true

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var relativeHumidity: Double {
        get async {
            let pct = service.characteristic(ofType: HMCharacteristicTypeCurrentRelativeHumidity)?.value as? Double ?? 0
            return pct / 100.0
        }
    }

    var humidityStream: AsyncStream<Double> { AsyncStream { _ in } }
}

// MARK: - Motion Sensor

struct HomeKitMotionCapability: MotionCapability {
    let capabilityID: CapabilityID = .motion
    let displayName = "Motion"
    let isReadOnly = true

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var motionDetected: Bool {
        get async {
            service.characteristic(ofType: HMCharacteristicTypeMotionDetected)?.value as? Bool ?? false
        }
    }

    var lastMotionDate: Date? { get async { nil } }
    var motionStream: AsyncStream<Bool> { AsyncStream { _ in } }
}

// MARK: - Contact Sensor

struct HomeKitContactCapability: ContactCapability {
    let capabilityID: CapabilityID = .contact
    let displayName = "Contact"
    let isReadOnly = true

    private let accessory: HMAccessory
    private let service: HMService

    init(accessory: HMAccessory, service: HMService) {
        self.accessory = accessory; self.service = service
    }

    var contactState: ContactState {
        get async {
            switch service.characteristic(ofType: HMCharacteristicTypeContactState)?.value as? UInt {
            case 0:  return .closed
            case 1:  return .open
            default: return .unknown
            }
        }
    }

    var contactStream: AsyncStream<ContactState> { AsyncStream { _ in } }
}

// MARK: - Comparable Clamp

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
