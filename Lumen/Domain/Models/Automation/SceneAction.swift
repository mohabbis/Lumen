import Foundation
import SwiftData

// MARK: - Scene Action (@Model)
// Persists a capability mutation for one device as part of a Scene.
// Uses flattened columns for payload since SwiftData doesn't support enums with associated values.

@Model
final class SceneAction {
    var id: UUID
    var scene: Scene?
    var deviceID: UUID
    var capabilityRaw: String
    var sortOrder: Int

    // Flattened payload storage
    var payloadTypeRaw: String
    var payloadBool: Bool?
    var payloadDouble: Double?
    var payloadInt: Int?
    var payloadHue: Double?
    var payloadSaturation: Double?
    var payloadBrightness: Double?

    init(
        id: UUID = UUID(),
        deviceID: UUID,
        capabilityID: CapabilityID,
        payload: ActionPayload,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.deviceID = deviceID
        self.capabilityRaw = capabilityID.rawValue
        self.sortOrder = sortOrder

        switch payload {
        case .bool(let v):
            payloadTypeRaw = "bool"; payloadBool = v
        case .double(let v):
            payloadTypeRaw = "double"; payloadDouble = v
        case .int(let v):
            payloadTypeRaw = "int"; payloadInt = v
        case .colorHSB(let h, let s, let b):
            payloadTypeRaw = "colorHSB"
            payloadHue = h; payloadSaturation = s; payloadBrightness = b
        case .temperature(let m):
            payloadTypeRaw = "temperature"
            payloadDouble = m.converted(to: .celsius).value
        case .hvacMode(let mode):
            payloadTypeRaw = "hvacMode"
            payloadInt = HVACMode.allCases.firstIndex(of: mode)
        case .lockState(let state):
            payloadTypeRaw = "lockState"
            payloadInt = LockState.allCases.firstIndex(of: state)
        }
    }

    var capabilityID: CapabilityID { CapabilityID(capabilityRaw) }

    func asSnapshot() -> SceneActionSnapshot? {
        let payload: ActionPayload?
        switch payloadTypeRaw {
        case "bool":
            payload = payloadBool.map { .bool($0) }
        case "double":
            payload = payloadDouble.map { .double($0) }
        case "int":
            payload = payloadInt.map { .int($0) }
        case "colorHSB":
            guard let h = payloadHue, let s = payloadSaturation, let b = payloadBrightness else {
                return nil
            }
            payload = .colorHSB(hue: h, saturation: s, brightness: b)
        case "temperature":
            payload = payloadDouble.map {
                .temperature(Measurement(value: $0, unit: .celsius))
            }
        case "hvacMode":
            payload = payloadInt.flatMap { HVACMode.allCases[safe: $0].map { .hvacMode($0) } }
        case "lockState":
            payload = payloadInt.flatMap { LockState.allCases[safe: $0].map { .lockState($0) } }
        default:
            return nil
        }
        guard let p = payload else { return nil }
        return SceneActionSnapshot(deviceID: deviceID, capabilityID: capabilityID, payload: p)
    }
}

// MARK: - Safe Collection Subscript

extension Collection {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
