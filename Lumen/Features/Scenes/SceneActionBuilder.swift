import Foundation

// MARK: - Scene Action Builder
// Pure helper for the scene editor: which capabilities a device exposes and
// sensible default payloads for each. Unit-tested without SwiftUI.

struct SceneActionOption: Identifiable, Equatable {
    let capabilityID: CapabilityID
    let displayName: String
    let defaultPayload: ActionPayload

    var id: String { capabilityID.rawValue }
}

struct SceneActionBuilder {

    /// Controllable capabilities on a device that can be added to a scene.
    static func options(for device: any SmartDevice) -> [SceneActionOption] {
        device.capabilities
            .filter { !$0.isReadOnly }
            .compactMap { capability in
                guard let payload = defaultPayload(for: capability.capabilityID) else { return nil }
                return SceneActionOption(
                    capabilityID: capability.capabilityID,
                    displayName: capability.displayName,
                    defaultPayload: payload
                )
            }
            .sorted { $0.displayName < $1.displayName }
    }

    static func defaultPayload(for capabilityID: CapabilityID) -> ActionPayload? {
        switch capabilityID {
        case .onOff:
            return .bool(true)
        case .brightness:
            return .double(0.5)
        case .colorTemperature:
            return .int(3000)
        case .colorHue:
            return .colorHSB(hue: 0.12, saturation: 0.4, brightness: 0.7)
        case .lock:
            return .lockState(.locked)
        case .position:
            return .double(0.5)
        case .targetTemperature:
            return .temperature(Measurement(value: 21, unit: .celsius))
        default:
            return nil
        }
    }

    /// Devices that expose at least one scene-eligible capability.
    static func eligibleDevices(from devices: [any SmartDevice]) -> [any SmartDevice] {
        devices
            .filter { !options(for: $0).isEmpty }
            .sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
    }
}
