import Foundation
import SwiftData
import Observation

// MARK: - Device Service
// Owns PlannedDevice CRUD and routes live control actions to the correct bridge.

@MainActor
@Observable
final class DeviceService {

    private let modelContext: ModelContext
    let stateStore: DeviceStateStore

    private(set) var registeredBridges: [BridgeID: any SmartHomeBridge] = [:]

    init(modelContext: ModelContext, stateStore: DeviceStateStore) {
        self.modelContext = modelContext
        self.stateStore = stateStore
    }

    // MARK: - Bridge Management

    func registerBridge(_ bridge: some SmartHomeBridge) {
        registeredBridges[bridge.id] = bridge
        stateStore.connect(bridge: bridge)
    }

    func unregisterBridge(_ id: BridgeID) async {
        if let bridge = registeredBridges.removeValue(forKey: id) {
            await bridge.shutdown()
        }
        await stateStore.disconnect(bridgeID: id)
    }

    // MARK: - Live Device Control

    func send(action: SceneActionSnapshot) async throws {
        guard let device = stateStore.device(id: action.deviceID) else {
            throw AppError.deviceNotFound(action.deviceID)
        }
        try stateStore.applyLocalAction(action)
        if device.bridgeID == .localPreview { return }

        guard let bridge = registeredBridges[device.bridgeID] else {
            throw AppError.bridgeNotFound(device.bridgeID)
        }
        guard device.reachability == .reachable else {
            throw AppError.deviceUnreachable(action.deviceID)
        }
        try await bridge.executeAction(action)
    }

    func setPower(_ on: Bool, deviceID: DeviceID) async throws {
        try await send(action: SceneActionSnapshot(
            deviceID: deviceID, capabilityID: .onOff, payload: .bool(on)
        ))
    }

    func setBrightness(_ brightness: Double, deviceID: DeviceID) async throws {
        try await send(action: SceneActionSnapshot(
            deviceID: deviceID, capabilityID: .brightness, payload: .double(brightness)
        ))
    }

    func setColorTemperature(_ kelvin: Int, deviceID: DeviceID) async throws {
        try await send(action: SceneActionSnapshot(
            deviceID: deviceID, capabilityID: .colorTemperature, payload: .int(kelvin)
        ))
    }

    func setColor(hue: Double, saturation: Double, deviceID: DeviceID) async throws {
        try await send(action: SceneActionSnapshot(
            deviceID: deviceID,
            capabilityID: .colorHue,
            payload: .colorHSB(hue: hue, saturation: saturation, brightness: 1.0)
        ))
    }

    func setLock(_ state: LockState, deviceID: DeviceID) async throws {
        try await send(action: SceneActionSnapshot(
            deviceID: deviceID, capabilityID: .lock, payload: .lockState(state)
        ))
    }

    @discardableResult
    func applyLocalScenePreset(named name: String) -> Int {
        stateStore.applyLocalScenePreset(named: name)
    }

    func syncLocalPreviewDevices(from home: Home?) {
        stateStore.syncLocalPreviewDevices(from: home)
    }

    func setLocalPreviewEnabled(_ isEnabled: Bool, home: Home?) {
        if isEnabled {
            stateStore.syncLocalPreviewDevices(from: home)
        } else {
            stateStore.removeAllLocalPreviewDevices()
        }
    }

    // MARK: - Planned Device CRUD

    @discardableResult
    func addPlannedDevice(
        name: String,
        type: DeviceType,
        to room: Room,
        manufacturer: String? = nil,
        model: String? = nil,
        notes: String? = nil
    ) throws -> PlannedDevice {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw AppError.invalidConfiguration(reason: "Device name cannot be empty.")
        }
        let device = PlannedDevice(
            name: cleaned, type: type,
            manufacturer: manufacturer, model: model, notes: notes
        )
        device.room = room
        room.plannedDevices.append(device)
        room.updatedAt = Date()
        try modelContext.save()
        stateStore.upsertLocalPreviewDevice(for: device, in: room)
        return device
    }

    func updatePlannedDevice(
        _ device: PlannedDevice,
        name: String? = nil,
        manufacturer: String? = nil,
        model: String? = nil,
        notes: String? = nil
    ) throws {
        if let name {
            let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else {
                throw AppError.invalidConfiguration(reason: "Device name cannot be empty.")
            }
            device.name = cleaned
        }
        if let manufacturer { device.manufacturer = manufacturer }
        if let model { device.model = model }
        if let notes { device.notes = notes }
        device.updatedAt = Date()
        try modelContext.save()
    }

    func deletePlannedDevice(_ device: PlannedDevice) throws {
        stateStore.removeLocalPreviewDevice(for: device)
        modelContext.delete(device)
        try modelContext.save()
    }

    // MARK: - Commissioning
    // Called when a PlannedDevice has been physically installed and discovered by a bridge.

    func commission(
        plannedDevice: PlannedDevice,
        liveDeviceID: DeviceID,
        bridgeID: BridgeID
    ) throws {
        plannedDevice.liveDeviceID = liveDeviceID
        plannedDevice.bridgeIDRaw = bridgeID.rawValue
        plannedDevice.isInstalled = true
        plannedDevice.planningStageRaw = PlanningStage.installed.rawValue
        plannedDevice.updatedAt = Date()
        try modelContext.save()

        // The planned device's local-preview entry keyed on its UUID is now stale —
        // future syncs re-key it onto liveDeviceID. Drop the orphan immediately so
        // the discovered live device isn't shadowed by a duplicate preview tile.
        stateStore.removeLocalPreviewDevice(for: plannedDevice)
    }

    /// Reverses a commissioning link, returning the planned device to the planning lifecycle.
    func decommission(plannedDevice: PlannedDevice) throws {
        plannedDevice.liveDeviceID = nil
        plannedDevice.bridgeIDRaw = nil
        plannedDevice.isInstalled = false
        plannedDevice.planningStageRaw = PlanningStage.planned.rawValue
        plannedDevice.updatedAt = Date()
        try modelContext.save()
    }

    /// Planned devices not yet linked to a live device — commissioning candidates.
    func uncommissionedPlannedDevices() throws -> [PlannedDevice] {
        let descriptor = FetchDescriptor<PlannedDevice>(
            predicate: #Predicate { $0.liveDeviceID == nil },
            sortBy: [SortDescriptor(\PlannedDevice.name)]
        )
        return try modelContext.fetch(descriptor)
    }

    /// The planned device currently linked to a given live device, if any.
    func plannedDevice(forLiveDeviceID id: DeviceID) throws -> PlannedDevice? {
        let descriptor = FetchDescriptor<PlannedDevice>(
            predicate: #Predicate { $0.liveDeviceID == id }
        )
        return try modelContext.fetch(descriptor).first
    }
}
