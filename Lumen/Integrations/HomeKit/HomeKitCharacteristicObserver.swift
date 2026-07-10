import Foundation
import HomeKit

// MARK: - HomeKit Accessory Delegate
// Bridges HMCharacteristic value updates into the HomeKitBridge actor.

final class HomeKitAccessoryObserver: NSObject, HMAccessoryDelegate, @unchecked Sendable {

    private let onCharacteristicUpdate: @Sendable (HMAccessory, HMCharacteristic) -> Void

    init(onCharacteristicUpdate: @escaping @Sendable (HMAccessory, HMCharacteristic) -> Void) {
        self.onCharacteristicUpdate = onCharacteristicUpdate
    }

    func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
        onCharacteristicUpdate(accessory, characteristic)
    }
}

// MARK: - Characteristic → Capability mapping

enum HomeKitCharacteristicMapper {

    static func capabilityID(for characteristicType: String) -> CapabilityID? {
        switch characteristicType {
        case HMCharacteristicTypePowerState:            return .onOff
        case HMCharacteristicTypeBrightness:            return .brightness
        case HMCharacteristicTypeColorTemperature:      return .colorTemperature
        case HMCharacteristicTypeHue, HMCharacteristicTypeSaturation: return .colorHue
        case HMCharacteristicTypeCurrentLockMechanismState,
             HMCharacteristicTypeTargetLockMechanismState: return .lock
        case HMCharacteristicTypeCurrentPosition,
             HMCharacteristicTypeTargetPosition:       return .position
        case HMCharacteristicTypeTargetTemperature:       return .targetTemperature
        case HMCharacteristicTypeCurrentTemperature:    return .temperature
        case HMCharacteristicTypeCurrentRelativeHumidity: return .humidity
        case HMCharacteristicTypeMotionDetected:        return .motion
        case HMCharacteristicTypeContactState:          return .contact
        default:                                        return nil
        }
    }

    static func motionValue(from characteristic: HMCharacteristic) -> Bool? {
        guard characteristic.characteristicType == HMCharacteristicTypeMotionDetected else { return nil }
        return characteristic.value as? Bool
    }

    static func contactValue(from characteristic: HMCharacteristic) -> ContactState? {
        guard characteristic.characteristicType == HMCharacteristicTypeContactState else { return nil }
        switch characteristic.value as? UInt {
        case 0:  return .closed
        case 1:  return .open
        default: return .unknown
        }
    }

    static var notifiableTypes: Set<String> {
        [
            HMCharacteristicTypePowerState,
            HMCharacteristicTypeBrightness,
            HMCharacteristicTypeColorTemperature,
            HMCharacteristicTypeHue,
            HMCharacteristicTypeSaturation,
            HMCharacteristicTypeCurrentLockMechanismState,
            HMCharacteristicTypeCurrentPosition,
            HMCharacteristicTypeTargetTemperature,
            HMCharacteristicTypeCurrentTemperature,
            HMCharacteristicTypeCurrentRelativeHumidity,
            HMCharacteristicTypeMotionDetected,
            HMCharacteristicTypeContactState
        ]
    }
}
