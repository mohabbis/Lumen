import Foundation
import Observation

// MARK: - Device View Model

@MainActor
@Observable
final class DeviceViewModel {

    private let deviceService: DeviceService
    private let stateStore: DeviceStateStore

    var error: (any Error)?
    var isRefreshing = false

    init(deviceService: DeviceService, stateStore: DeviceStateStore) {
        self.deviceService = deviceService
        self.stateStore = stateStore
    }

    // MARK: - Derived State

    var liveDevices: [any SmartDevice] { stateStore.allDevices }

    var liveDevicesByCategory: [(DeviceCategory, [any SmartDevice])] {
        let grouped = Dictionary(grouping: stateStore.allDevices) { $0.category }
        return DeviceCategory.allCases
            .compactMap { cat in
                guard let devices = grouped[cat], !devices.isEmpty else { return nil }
                return (cat, devices.sorted { $0.displayName < $1.displayName })
            }
    }

    var reachableCount: Int { stateStore.reachableCount }
    var totalCount: Int { stateStore.allDevices.count }
    var homekitStatus: BridgeStatus { stateStore.bridgeStatuses[.homeKit] ?? .idle }

    func device(id: DeviceID) -> (any SmartDevice)? {
        stateStore.device(id: id)
    }

    func controlState(for device: any SmartDevice) -> LocalDeviceState {
        stateStore.controlState(for: device)
    }

    func isLocalPreview(_ device: any SmartDevice) -> Bool {
        device.bridgeID == .localPreview
    }

    // MARK: - Actions

    func setPower(_ on: Bool, deviceID: DeviceID) {
        Task {
            do { try await deviceService.setPower(on, deviceID: deviceID) }
            catch { self.error = error }
        }
    }

    func setBrightness(_ value: Double, deviceID: DeviceID) {
        Task {
            do { try await deviceService.setBrightness(value, deviceID: deviceID) }
            catch { self.error = error }
        }
    }

    func setColorTemperature(_ kelvin: Int, deviceID: DeviceID) {
        Task {
            do { try await deviceService.setColorTemperature(kelvin, deviceID: deviceID) }
            catch { self.error = error }
        }
    }

    func setColor(hue: Double, saturation: Double, deviceID: DeviceID) {
        Task {
            do { try await deviceService.setColor(hue: hue, saturation: saturation, deviceID: deviceID) }
            catch { self.error = error }
        }
    }

    func setLock(_ state: LockState, deviceID: DeviceID) {
        Task {
            do { try await deviceService.setLock(state, deviceID: deviceID) }
            catch { self.error = error }
        }
    }

    func refresh() async {
        isRefreshing = true
        await stateStore.refreshAll()
        isRefreshing = false
    }

    // MARK: - Commissioning
    // Links a discovered live device to a PlannedDevice in the home model.

    /// A live device is commissionable if it comes from a real bridge (not a local
    /// preview tile, which is itself the projection of a PlannedDevice).
    func isCommissionable(_ device: any SmartDevice) -> Bool {
        device.bridgeID != .localPreview
    }

    func uncommissionedPlannedDevices() -> [PlannedDevice] {
        (try? deviceService.uncommissionedPlannedDevices()) ?? []
    }

    func linkedPlannedDevice(for device: any SmartDevice) -> PlannedDevice? {
        try? deviceService.plannedDevice(forLiveDeviceID: device.id)
    }

    func commission(_ planned: PlannedDevice, to device: any SmartDevice) {
        do {
            try deviceService.commission(
                plannedDevice: planned,
                liveDeviceID: device.id,
                bridgeID: device.bridgeID
            )
        } catch {
            self.error = error
        }
    }

    func decommission(_ planned: PlannedDevice) {
        do { try deviceService.decommission(plannedDevice: planned) }
        catch { self.error = error }
    }
}
