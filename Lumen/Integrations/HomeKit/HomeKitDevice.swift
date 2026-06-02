import Foundation
import HomeKit

// MARK: - HomeKit Device
// Wraps HMAccessory as a SmartDevice.
// HMAccessory never escapes this file — the rest of the app is HomeKit-agnostic.

struct HomeKitDevice: SmartDevice {

    let id: DeviceID
    let displayName: String
    let roomName: String?
    let bridgeID: BridgeID = .homeKit
    let reachability: DeviceReachability
    let category: DeviceCategory

    private let accessory: HMAccessory
    private let _capabilities: [any DeviceCapability]

    var capabilities: [any DeviceCapability] { _capabilities }

    init(accessory: HMAccessory, homeName: String) {
        self.id = accessory.uniqueIdentifier
        self.displayName = accessory.name
        self.roomName = accessory.room?.name
        self.reachability = accessory.isReachable ? .reachable : .unreachable
        self.category = DeviceCategory.from(accessory.category.categoryType)
        self.accessory = accessory
        self._capabilities = Self.buildCapabilities(from: accessory)
    }

    // MARK: - Action Execution (called by HomeKitBridge)

    func execute(_ action: SceneActionSnapshot) async throws {
        switch action.capabilityID {
        case .onOff:
            guard case .bool(let on) = action.payload else { return }
            try await write(characteristicType: HMCharacteristicTypePowerState, value: on)

        case .brightness:
            guard case .double(let level) = action.payload else { return }
            try await write(characteristicType: HMCharacteristicTypeBrightness, value: Int(level * 100))

        case .colorTemperature:
            guard case .int(let kelvin) = action.payload else { return }
            let mireds = max(1, 1_000_000 / kelvin)
            try await write(characteristicType: HMCharacteristicTypeColorTemperature, value: mireds)

        case .colorHue:
            guard case .colorHSB(let h, let s, _) = action.payload else { return }
            try await write(characteristicType: HMCharacteristicTypeHue, value: h * 360.0)
            try await write(characteristicType: HMCharacteristicTypeSaturation, value: s * 100.0)

        case .lock:
            guard case .lockState(let state) = action.payload else { return }
            let value: UInt = state == .locked ? 1 : 0
            try await write(characteristicType: HMCharacteristicTypeTargetLockMechanismState, value: value)

        case .targetTemperature:
            guard case .temperature(let m) = action.payload else { return }
            try await write(characteristicType: HMCharacteristicTypeTargetTemperature,
                            value: m.converted(to: .celsius).value)

        case .position:
            guard case .double(let pos) = action.payload else { return }
            try await write(characteristicType: HMCharacteristicTypeCurrentPosition, value: Int(pos * 100))

        default:
            throw AppError.capabilityNotSupported(action.capabilityID, deviceID: id)
        }
    }

    // MARK: - Capability Discovery

    private static func buildCapabilities(from accessory: HMAccessory) -> [any DeviceCapability] {
        var caps: [any DeviceCapability] = []

        for service in accessory.services {
            switch service.serviceType {

            case HMServiceTypeLightbulb, HMServiceTypeOutlet, HMServiceTypeSwitch:
                if service.characteristic(ofType: HMCharacteristicTypePowerState) != nil {
                    caps.append(HomeKitOnOffCapability(accessory: accessory, service: service))
                }
                if service.characteristic(ofType: HMCharacteristicTypeBrightness) != nil {
                    caps.append(HomeKitBrightnessCapability(accessory: accessory, service: service))
                }
                if service.characteristic(ofType: HMCharacteristicTypeColorTemperature) != nil {
                    caps.append(HomeKitColorTemperatureCapability(accessory: accessory, service: service))
                }
                if service.characteristic(ofType: HMCharacteristicTypeHue) != nil,
                   service.characteristic(ofType: HMCharacteristicTypeSaturation) != nil {
                    caps.append(HomeKitColorHueCapability(accessory: accessory, service: service))
                }

            case HMServiceTypeLockMechanism:
                caps.append(HomeKitLockCapability(accessory: accessory, service: service))

            case HMServiceTypeThermostat:
                caps.append(HomeKitTargetTemperatureCapability(accessory: accessory, service: service))

            case HMServiceTypeTemperatureSensor:
                caps.append(HomeKitTemperatureSensorCapability(accessory: accessory, service: service))

            case HMServiceTypeHumiditySensor:
                caps.append(HomeKitHumiditySensorCapability(accessory: accessory, service: service))

            case HMServiceTypeMotionSensor:
                caps.append(HomeKitMotionCapability(accessory: accessory, service: service))

            case HMServiceTypeContactSensor:
                caps.append(HomeKitContactCapability(accessory: accessory, service: service))

            case HMServiceTypeWindowCovering:
                caps.append(HomeKitPositionCapability(accessory: accessory, service: service))

            default:
                break
            }
        }

        return caps
    }

    // MARK: - Private Write Helper

    private func write(characteristicType type: String, value: any Any) async throws {
        for service in accessory.services {
            if let char = service.characteristic(ofType: type) {
                try await char.writeValue(value)
                return
            }
        }
        throw AppError.capabilityNotSupported(CapabilityID(type), deviceID: id)
    }
}

// MARK: - DeviceCategory ← HMAccessoryCategoryType

extension DeviceCategory {
    static func from(_ hmType: String) -> DeviceCategory {
        switch hmType {
        case HMAccessoryCategoryTypeLightbulb,
             HMAccessoryCategoryTypeOutlet,
             HMAccessoryCategoryTypeSwitch:
            return .lighting
        case HMAccessoryCategoryTypeThermostat,
             HMAccessoryCategoryTypeAirConditioner,
             HMAccessoryCategoryTypeFan,
             HMAccessoryCategoryTypeAirPurifier:
            return .climate
        case HMAccessoryCategoryTypeDoorLock,
             HMAccessoryCategoryTypeSecuritySystem,
             HMAccessoryCategoryTypeDoor,
             HMAccessoryCategoryTypeSensor:
            return .security
        case HMAccessoryCategoryTypeWindowCovering,
             HMAccessoryCategoryTypeGarageDoorOpener:
            return .other
        default:
            return .other
        }
    }
}
