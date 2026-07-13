import XCTest
import SwiftData
@testable import Lumen

// Direct coverage for DeviceStateStore's pure logic (local-action value
// clamping, scene-preset mapping, stale local-preview cleanup) and its bridge
// lifecycle (discover → merge → notify, disconnect, live state stream,
// authorization failure). Previously the store was only instantiated
// incidentally by other suites and none of this was asserted.
@MainActor
final class DeviceStateStoreTests: XCTestCase {

    private var container: ModelContainer!

    // MARK: - Fixtures

    /// A store holding a single local-preview light (supports onOff, brightness,
    /// colorTemperature, colorHue). Returns the device's ID for building actions.
    private func makeStoreWithLight() -> (DeviceStateStore, DeviceID) {
        let store = DeviceStateStore()
        let planned = PlannedDevice(name: "Lamp", type: .light)
        store.upsertLocalPreviewDevice(for: planned, in: nil)
        return (store, planned.id)
    }

    private func action(
        _ id: DeviceID,
        _ capability: CapabilityID,
        _ payload: ActionPayload
    ) -> SceneActionSnapshot {
        SceneActionSnapshot(deviceID: id, capabilityID: capability, payload: payload)
    }

    // MARK: - controlState defaults

    func testControlStateReturnsDefaultsForLight() {
        let (store, id) = makeStoreWithLight()
        let device = store.device(id: id)!
        let state = store.controlState(for: device)
        XCTAssertTrue(state.isPowered)                          // light supports onOff
        XCTAssertEqual(state.brightness, 0.72, accuracy: 0.0001)
    }

    // MARK: - applyLocalAction: clamping & implicit power

    func testApplyOnOffSetsPower() throws {
        let (store, id) = makeStoreWithLight()
        try store.applyLocalAction(action(id, .onOff, .bool(false)))
        XCTAssertFalse(store.controlState(for: store.device(id: id)!).isPowered)
    }

    func testApplyBrightnessClampsAboveOne() throws {
        let (store, id) = makeStoreWithLight()
        try store.applyLocalAction(action(id, .brightness, .double(2.0)))
        XCTAssertEqual(store.controlState(for: store.device(id: id)!).brightness, 1.0, accuracy: 0.0001)
    }

    func testApplyPositiveBrightnessImplicitlyPowersOn() throws {
        let (store, id) = makeStoreWithLight()
        try store.applyLocalAction(action(id, .onOff, .bool(false)))
        try store.applyLocalAction(action(id, .brightness, .double(0.5)))
        let state = store.controlState(for: store.device(id: id)!)
        XCTAssertTrue(state.isPowered, "Non-zero brightness should turn the device on")
        XCTAssertEqual(state.brightness, 0.5, accuracy: 0.0001)
    }

    func testApplyColorTemperatureClampsToRange() throws {
        let (store, id) = makeStoreWithLight()
        try store.applyLocalAction(action(id, .colorTemperature, .int(9000)))
        XCTAssertEqual(store.controlState(for: store.device(id: id)!).colorTemperature, 6500)
        try store.applyLocalAction(action(id, .colorTemperature, .int(1000)))
        XCTAssertEqual(store.controlState(for: store.device(id: id)!).colorTemperature, 1800)
    }

    func testApplyColorHueClampsComponents() throws {
        let (store, id) = makeStoreWithLight()
        try store.applyLocalAction(action(id, .colorHue, .colorHSB(hue: 1.5, saturation: -0.2, brightness: 0.5)))
        let state = store.controlState(for: store.device(id: id)!)
        XCTAssertEqual(state.hue, 1.0, accuracy: 0.0001)
        XCTAssertEqual(state.saturation, 0.0, accuracy: 0.0001)
        XCTAssertEqual(state.brightness, 0.5, accuracy: 0.0001)
    }

    // MARK: - applyLocalAction: error branches

    func testApplyThrowsForUnsupportedCapability() {
        let (store, id) = makeStoreWithLight() // light has no lock capability
        XCTAssertThrowsError(try store.applyLocalAction(action(id, .lock, .lockState(.unlocked)))) { error in
            guard case AppError.capabilityNotSupported = error else {
                return XCTFail("Expected capabilityNotSupported, got \(error)")
            }
        }
    }

    func testApplyThrowsForUnknownDevice() {
        let (store, _) = makeStoreWithLight()
        XCTAssertThrowsError(try store.applyLocalAction(action(UUID(), .onOff, .bool(true)))) { error in
            guard case AppError.deviceNotFound = error else {
                return XCTFail("Expected deviceNotFound, got \(error)")
            }
        }
    }

    // MARK: - applyLocalScenePreset

    func testAwayPresetTurnsLightOff() {
        let (store, id) = makeStoreWithLight()
        let count = store.applyLocalScenePreset(named: "Away")
        XCTAssertEqual(count, 1)
        XCTAssertFalse(store.controlState(for: store.device(id: id)!).isPowered)
    }

    func testMoviePresetAppliesDimColor() {
        let (store, id) = makeStoreWithLight()
        store.applyLocalScenePreset(named: "Movie Night")
        let state = store.controlState(for: store.device(id: id)!)
        XCTAssertEqual(state.hue, 0.73, accuracy: 0.0001)
        XCTAssertEqual(state.brightness, 0.18, accuracy: 0.0001)
    }

    func testMorningPresetSetsWarmDaylightTemperature() {
        let (store, id) = makeStoreWithLight()
        store.applyLocalScenePreset(named: "Morning")
        XCTAssertEqual(store.controlState(for: store.device(id: id)!).colorTemperature, 3200)
    }

    func testEveningPresetSetsWarmTemperature() {
        let (store, id) = makeStoreWithLight()
        store.applyLocalScenePreset(named: "Evening")
        XCTAssertEqual(store.controlState(for: store.device(id: id)!).colorTemperature, 2400)
    }

    func testUnknownPresetFallsBackToPowerOn() {
        let (store, id) = makeStoreWithLight()
        try? store.applyLocalAction(action(id, .onOff, .bool(false)))
        let count = store.applyLocalScenePreset(named: "Something Custom")
        XCTAssertEqual(count, 1)
        XCTAssertTrue(store.controlState(for: store.device(id: id)!).isPowered)
    }

    // MARK: - syncLocalPreviewDevices

    private func makeHomeFixture(deviceCount: Int) throws -> (Home, Room, ModelContext) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        let home = Home(name: "Test Home", isPrimary: true)
        let room = Room(name: "Living Room", type: .other)
        room.home = home
        home.rooms.append(room)
        for i in 0..<deviceCount {
            let planned = PlannedDevice(name: "Device \(i)", type: .light)
            planned.room = room
            room.plannedDevices.append(planned)
        }
        ctx.insert(home)
        try ctx.save()
        return (home, room, ctx)
    }

    func testSyncPopulatesPreviewDevicesFromHome() throws {
        let store = DeviceStateStore()
        let (home, _, _) = try makeHomeFixture(deviceCount: 2)
        store.syncLocalPreviewDevices(from: home)
        XCTAssertEqual(store.allDevices.count, 2)
    }

    func testSyncRemovesStalePreviewDevices() throws {
        let store = DeviceStateStore()
        let (home, room, ctx) = try makeHomeFixture(deviceCount: 2)
        store.syncLocalPreviewDevices(from: home)
        XCTAssertEqual(store.allDevices.count, 2)

        // Remove one planned device from the model, then re-sync.
        let doomed = room.plannedDevices[0]
        room.plannedDevices.remove(at: 0)
        ctx.delete(doomed)
        try ctx.save()

        store.syncLocalPreviewDevices(from: home)
        XCTAssertEqual(store.allDevices.count, 1, "Stale preview device should be dropped on re-sync")
    }

    func testSyncWithNilHomeIsNoOp() {
        let (store, _) = makeStoreWithLight()
        store.syncLocalPreviewDevices(from: nil)
        XCTAssertEqual(store.allDevices.count, 1)
    }

    func testRemoveAllLocalPreviewDevicesClearsStore() {
        let (store, _) = makeStoreWithLight()
        store.removeAllLocalPreviewDevices()
        XCTAssertTrue(store.allDevices.isEmpty)
    }

    // MARK: - Bridge lifecycle

    func testConnectDiscoversDevicesAndReportsStatus() async {
        let store = DeviceStateStore()
        let bridgeID = BridgeID("fake")
        let device = TestSmartDevice(bridgeID: bridgeID)
        let bridge = FakeSmartHomeBridge(id: bridgeID, devices: [device])

        let discovered = expectation(description: "onDevicesDiscovered")
        discovered.assertForOverFulfill = false
        store.onDevicesDiscovered = { _ in discovered.fulfill() }

        store.connect(bridge: bridge)
        await fulfillment(of: [discovered], timeout: 2)

        XCTAssertNotNil(store.device(id: device.id))
        XCTAssertEqual(store.reachableCount, 1)
        await waitUntil { store.bridgeStatuses[bridgeID]?.isOperational == true }
        XCTAssertEqual(store.bridgeStatuses[bridgeID]?.isOperational, true)

        await store.disconnect(bridgeID: bridgeID)
    }

    func testDisconnectRemovesDevicesAndStatus() async {
        let store = DeviceStateStore()
        let bridgeID = BridgeID("fake")
        let device = TestSmartDevice(bridgeID: bridgeID)
        let bridge = FakeSmartHomeBridge(id: bridgeID, devices: [device])

        let discovered = expectation(description: "discovered")
        discovered.assertForOverFulfill = false
        store.onDevicesDiscovered = { _ in discovered.fulfill() }
        store.connect(bridge: bridge)
        await fulfillment(of: [discovered], timeout: 2)

        var removed: [DeviceID] = []
        store.onDevicesRemoved = { removed = $0 }
        await store.disconnect(bridgeID: bridgeID)

        XCTAssertNil(store.device(id: device.id))
        XCTAssertNil(store.bridgeStatuses[bridgeID])
        XCTAssertEqual(removed, [device.id])
    }

    func testLiveStateStreamUpdatesDevice() async {
        let store = DeviceStateStore()
        let bridgeID = BridgeID("fake")
        let id = UUID()
        let device = TestSmartDevice(id: id, reachability: .reachable, bridgeID: bridgeID)
        let bridge = FakeSmartHomeBridge(id: bridgeID, devices: [device])

        let discovered = expectation(description: "discovered")
        discovered.assertForOverFulfill = false
        store.onDevicesDiscovered = { _ in discovered.fulfill() }
        store.connect(bridge: bridge)
        await fulfillment(of: [discovered], timeout: 2)
        XCTAssertEqual(store.device(id: id)?.reachability, .reachable)

        // Bridge now reports the device as unreachable; a state change should
        // pull the fresh device into the store.
        await waitForStreamOpen(bridge)
        let updated = TestSmartDevice(id: id, reachability: .unreachable, bridgeID: bridgeID)
        await bridge.upsert(updated)
        await bridge.emit(DeviceStateChange(deviceID: id, capabilityID: .onOff))

        await waitUntil { store.device(id: id)?.reachability == .unreachable }
        XCTAssertEqual(store.device(id: id)?.reachability, .unreachable)

        await store.disconnect(bridgeID: bridgeID)
    }

    func testConnectSurfacesAuthorizationError() async {
        let store = DeviceStateStore()
        let bridgeID = BridgeID("fake")
        let bridge = FakeSmartHomeBridge(
            id: bridgeID,
            devices: [TestSmartDevice(bridgeID: bridgeID)],
            authorizeError: AppError.bridgeAuthorizationDenied(bridgeID)
        )

        store.connect(bridge: bridge)

        await waitUntil {
            if case .error = store.bridgeStatuses[bridgeID] { return true }
            return false
        }
        guard case .error = store.bridgeStatuses[bridgeID] else {
            return XCTFail("Expected bridge status to be .error after authorization failure")
        }
        // Discovery never ran, so no devices were merged.
        XCTAssertTrue(store.allDevices.isEmpty)

        await store.disconnect(bridgeID: bridgeID)
    }
}
