import Foundation
import Observation

// MARK: - Device State Store
// In-memory live state for all connected devices.
// Never persisted to disk. Rebuilt from bridges on every launch.
// All mutations happen on @MainActor; bridges communicate via async streams.

@MainActor
@Observable
final class DeviceStateStore {

    // MARK: - State

    private(set) var devicesByID: [DeviceID: any SmartDevice] = [:]
    private(set) var localStates: [DeviceID: LocalDeviceState] = [:]
    private(set) var lastUpdated: [DeviceID: Date] = [:]
    private(set) var bridgeStatuses: [BridgeID: BridgeStatus] = [:]

    private var bridgeTasks: [BridgeID: Task<Void, Never>] = [:]
    private var registeredBridges: [BridgeID: any SmartHomeBridge] = [:]

    var onDevicesDiscovered: (([any SmartDevice]) -> Void)?
    var onDevicesRemoved: (([DeviceID]) -> Void)?

    // MARK: - Derived Queries (computed, not stored — no duplication)

    var allDevices: [any SmartDevice] {
        Array(devicesByID.values)
    }

    var reachableCount: Int {
        devicesByID.values.filter { $0.reachability == .reachable }.count
    }

    func device(id: DeviceID) -> (any SmartDevice)? {
        devicesByID[id]
    }

    func devices(inRoom roomName: String) -> [any SmartDevice] {
        devicesByID.values
            .filter { $0.roomName == roomName }
            .sorted { $0.displayName < $1.displayName }
    }

    func devices(category: DeviceCategory) -> [any SmartDevice] {
        devicesByID.values.filter { $0.category == category }
    }

    func bridge(id: BridgeID) -> (any SmartHomeBridge)? {
        registeredBridges[id]
    }

    func controlState(for device: any SmartDevice) -> LocalDeviceState {
        localStates[device.id] ?? LocalDeviceState.defaults(for: device)
    }

    func upsertLocalPreviewDevice(for plannedDevice: PlannedDevice, in room: Room?) {
        let preview = LocalSmartDevice(plannedDevice: plannedDevice, roomName: room?.name)
        devicesByID[preview.id] = preview
        if localStates[preview.id] == nil {
            localStates[preview.id] = LocalDeviceState.defaults(for: preview)
        }
        lastUpdated[preview.id] = Date()
    }

    func syncLocalPreviewDevices(from home: Home?) {
        guard let home else { return }

        var validIDs = Set<DeviceID>()
        for room in home.rooms {
            for planned in room.plannedDevices {
                let previewID = planned.liveDeviceID ?? planned.id
                validIDs.insert(previewID)
                upsertLocalPreviewDevice(for: planned, in: room)
            }
        }

        let staleLocalIDs = devicesByID.values
            .filter { $0.bridgeID == .localPreview && !validIDs.contains($0.id) }
            .map(\.id)
        for id in staleLocalIDs {
            devicesByID.removeValue(forKey: id)
            localStates.removeValue(forKey: id)
            lastUpdated.removeValue(forKey: id)
        }
    }

    func removeLocalPreviewDevice(for plannedDevice: PlannedDevice) {
        let previewID = plannedDevice.liveDeviceID ?? plannedDevice.id
        devicesByID.removeValue(forKey: previewID)
        localStates.removeValue(forKey: previewID)
        lastUpdated.removeValue(forKey: previewID)
    }

    func removeAllLocalPreviewDevices() {
        let ids = devicesByID.values
            .filter { $0.bridgeID == .localPreview }
            .map(\.id)
        for id in ids {
            devicesByID.removeValue(forKey: id)
            localStates.removeValue(forKey: id)
            lastUpdated.removeValue(forKey: id)
        }
    }

    func applyLocalAction(_ action: SceneActionSnapshot) throws {
        guard let device = devicesByID[action.deviceID] else {
            throw AppError.deviceNotFound(action.deviceID)
        }
        guard device.supports(action.capabilityID) else {
            throw AppError.capabilityNotSupported(action.capabilityID, deviceID: action.deviceID)
        }

        var state = controlState(for: device)
        switch (action.capabilityID, action.payload) {
        case (.onOff, .bool(let isOn)):
            state.isPowered = isOn
        case (.brightness, .double(let value)):
            state.brightness = value.clamped(to: 0...1)
            if state.brightness > 0 { state.isPowered = true }
        case (.colorTemperature, .int(let kelvin)):
            state.colorTemperature = kelvin.clamped(to: 1800...6500)
            state.isPowered = true
        case (.colorHue, .colorHSB(let hue, let saturation, let brightness)):
            state.hue = hue.clamped(to: 0...1)
            state.saturation = saturation.clamped(to: 0...1)
            state.brightness = brightness.clamped(to: 0...1)
            state.isPowered = state.brightness > 0
        case (.lock, .lockState(let lockState)):
            state.lockState = lockState
        default:
            break
        }

        localStates[action.deviceID] = state
        lastUpdated[action.deviceID] = Date()
    }

    @discardableResult
    func applyLocalScenePreset(named sceneName: String) -> Int {
        let normalized = sceneName.lowercased()
        var count = 0

        for device in devicesByID.values where device.bridgeID == .localPreview || device.isControllable {
            if device.category == .lighting || device.supports(.onOff) {
                let action = presetAction(for: normalized, device: device)
                if let action, (try? applyLocalAction(action)) != nil {
                    count += 1
                }
            }
        }

        return count
    }

    // MARK: - Bridge Lifecycle

    func connect(bridge: some SmartHomeBridge) {
        let bridgeID = bridge.id
        registeredBridges[bridgeID] = bridge
        bridgeStatuses[bridgeID] = .connecting

        bridgeTasks[bridgeID] = Task {
            do {
                try await bridge.authorize()
                let status = await bridge.status
                updateBridgeStatus(status, for: bridgeID)

                let discovered = try await bridge.discover()
                mergeDevices(discovered)

                for await change in await bridge.deviceStateStream() {
                    await processStateChange(change, from: bridge)
                }
            } catch {
                updateBridgeStatus(.error(error), for: bridgeID)
            }
        }
    }

    func disconnect(bridgeID: BridgeID) async {
        bridgeTasks[bridgeID]?.cancel()
        bridgeTasks.removeValue(forKey: bridgeID)

        if let bridge = registeredBridges.removeValue(forKey: bridgeID) {
            await bridge.shutdown()
        }

        let orphaned = devicesByID.values.filter { $0.bridgeID == bridgeID }.map { $0.id }
        for id in orphaned { devicesByID.removeValue(forKey: id) }
        onDevicesRemoved?(orphaned)
        bridgeStatuses.removeValue(forKey: bridgeID)
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            for bridge in registeredBridges.values {
                group.addTask {
                    guard let fresh = try? await bridge.discover() else { return }
                    await self.mergeDevices(fresh)
                }
            }
        }
    }

    // MARK: - Private

    private func mergeDevices(_ devices: [any SmartDevice]) {
        for device in devices {
            devicesByID[device.id] = device
            if localStates[device.id] == nil {
                localStates[device.id] = LocalDeviceState.defaults(for: device)
            }
            lastUpdated[device.id] = Date()
        }
        onDevicesDiscovered?(Array(devicesByID.values))
    }

    private func updateBridgeStatus(_ status: BridgeStatus, for id: BridgeID) {
        bridgeStatuses[id] = status
    }

    private func processStateChange(
        _ change: DeviceStateChange,
        from bridge: some SmartHomeBridge
    ) async {
        guard let updated = await bridge.device(withID: change.deviceID) else { return }
        devicesByID[change.deviceID] = updated
        if localStates[change.deviceID] == nil {
            localStates[change.deviceID] = LocalDeviceState.defaults(for: updated)
        }
        lastUpdated[change.deviceID] = change.timestamp
    }

    private func presetAction(for normalizedSceneName: String, device: any SmartDevice) -> SceneActionSnapshot? {
        if normalizedSceneName.contains("away") || normalizedSceneName.contains("sleep") {
            guard device.supports(.onOff) else { return nil }
            return SceneActionSnapshot(deviceID: device.id, capabilityID: .onOff, payload: .bool(false))
        }

        if normalizedSceneName.contains("movie") {
            if device.supports(.colorHue) {
                return SceneActionSnapshot(
                    deviceID: device.id,
                    capabilityID: .colorHue,
                    payload: .colorHSB(hue: 0.73, saturation: 0.42, brightness: 0.18)
                )
            }
            if device.supports(.brightness) {
                return SceneActionSnapshot(deviceID: device.id, capabilityID: .brightness, payload: .double(0.18))
            }
        }

        if normalizedSceneName.contains("morning") {
            if device.supports(.colorTemperature) {
                return SceneActionSnapshot(deviceID: device.id, capabilityID: .colorTemperature, payload: .int(3200))
            }
            if device.supports(.brightness) {
                return SceneActionSnapshot(deviceID: device.id, capabilityID: .brightness, payload: .double(0.78))
            }
        }

        if normalizedSceneName.contains("evening") {
            if device.supports(.colorTemperature) {
                return SceneActionSnapshot(deviceID: device.id, capabilityID: .colorTemperature, payload: .int(2400))
            }
            if device.supports(.brightness) {
                return SceneActionSnapshot(deviceID: device.id, capabilityID: .brightness, payload: .double(0.42))
            }
        }

        guard device.supports(.onOff) else { return nil }
        return SceneActionSnapshot(deviceID: device.id, capabilityID: .onOff, payload: .bool(true))
    }
}
