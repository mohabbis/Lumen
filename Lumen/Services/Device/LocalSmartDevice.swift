import Foundation

// MARK: - Local Smart Device
// A session-local preview device for planned hardware. This is not real hardware
// control; it lets the prototype exercise UI, rooms, scenes, and controls safely.

struct LocalDeviceState: Equatable, Sendable {
    var isPowered: Bool
    var brightness: Double
    var colorTemperature: Int
    var hue: Double
    var saturation: Double
    var lockState: LockState
    var motionDetected: Bool
    var contactState: ContactState
    var currentTemperatureCelsius: Double

    static func defaults(for device: any SmartDevice) -> LocalDeviceState {
        LocalDeviceState(
            isPowered: device.supports(.onOff),
            brightness: device.supports(.brightness) ? 0.72 : 0,
            colorTemperature: 3000,
            hue: 0.09,
            saturation: 0.38,
            lockState: .locked,
            motionDetected: false,
            contactState: .closed,
            currentTemperatureCelsius: 21.0
        )
    }
}

struct LocalSmartDevice: SmartDevice {
    let id: DeviceID
    let displayName: String
    let roomName: String?
    let reachability: DeviceReachability = .reachable
    let bridgeID: BridgeID = .localPreview
    let category: DeviceCategory
    let capabilities: [any DeviceCapability]

    init(plannedDevice: PlannedDevice, roomName: String?) {
        id = plannedDevice.liveDeviceID ?? plannedDevice.id
        displayName = plannedDevice.displayName
        self.roomName = roomName
        category = plannedDevice.type.deviceCategory
        capabilities = plannedDevice.type.localPreviewCapabilities
    }
}

struct LocalPreviewCapability: DeviceCapability {
    let capabilityID: CapabilityID
    let displayName: String
    let isReadOnly: Bool
}

extension BridgeID {
    static let localPreview = BridgeID("localPreview")
}

extension DeviceType {
    var deviceCategory: DeviceCategory {
        switch self {
        case .light, .switchDevice, .dimmer:
            return .lighting
        case .thermostat, .airPurifier, .fan:
            return .climate
        case .doorLock, .camera:
            return .security
        case .motionSensor, .contactSensor, .temperatureSensor, .humiditySensor:
            return .sensors
        case .speaker, .tv, .streamingBox:
            return .entertainment
        case .vacuum:
            return .appliances
        case .windowCover:
            return .other
        }
    }

    var localPreviewCapabilities: [any DeviceCapability] {
        switch self {
        case .light:
            return [
                LocalPreviewCapability(capabilityID: .onOff, displayName: "Power", isReadOnly: false),
                LocalPreviewCapability(capabilityID: .brightness, displayName: "Brightness", isReadOnly: false),
                LocalPreviewCapability(capabilityID: .colorTemperature, displayName: "Color Temperature", isReadOnly: false),
                LocalPreviewCapability(capabilityID: .colorHue, displayName: "Color", isReadOnly: false)
            ]
        case .dimmer:
            return [
                LocalPreviewCapability(capabilityID: .onOff, displayName: "Power", isReadOnly: false),
                LocalPreviewCapability(capabilityID: .brightness, displayName: "Brightness", isReadOnly: false),
                LocalPreviewCapability(capabilityID: .colorTemperature, displayName: "Color Temperature", isReadOnly: false)
            ]
        case .switchDevice, .fan, .airPurifier, .speaker, .tv, .streamingBox, .vacuum:
            return [LocalPreviewCapability(capabilityID: .onOff, displayName: "Power", isReadOnly: false)]
        case .thermostat:
            return [
                LocalPreviewCapability(capabilityID: .temperature, displayName: "Current Temperature", isReadOnly: true),
                LocalPreviewCapability(capabilityID: .targetTemperature, displayName: "Target Temperature", isReadOnly: false)
            ]
        case .doorLock:
            return [LocalPreviewCapability(capabilityID: .lock, displayName: "Lock", isReadOnly: false)]
        case .motionSensor:
            return [LocalPreviewCapability(capabilityID: .motion, displayName: "Motion", isReadOnly: true)]
        case .contactSensor:
            return [LocalPreviewCapability(capabilityID: .contact, displayName: "Contact", isReadOnly: true)]
        case .temperatureSensor:
            return [LocalPreviewCapability(capabilityID: .temperature, displayName: "Temperature", isReadOnly: true)]
        case .humiditySensor:
            return [LocalPreviewCapability(capabilityID: .humidity, displayName: "Humidity", isReadOnly: true)]
        case .camera:
            return [LocalPreviewCapability(capabilityID: .motion, displayName: "Motion", isReadOnly: true)]
        case .windowCover:
            return [LocalPreviewCapability(capabilityID: .position, displayName: "Position", isReadOnly: false)]
        }
    }
}
