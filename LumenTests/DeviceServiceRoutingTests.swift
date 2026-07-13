import XCTest
import SwiftData
@testable import Lumen

// Coverage for DeviceService.send(action:) routing — the branch that decides
// whether a control action short-circuits as a local-preview update or is
// forwarded to a real bridge, plus its error branches. Every prior device test
// hit only the `.localPreview` path, so bridge forwarding, unreachable, and
// bridge-not-found were untested.
@MainActor
final class DeviceServiceRoutingTests: XCTestCase {

    private var container: ModelContainer!

    private func makeService() -> (DeviceService, DeviceStateStore) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let store = DeviceStateStore()
        let service = DeviceService(modelContext: container.mainContext, stateStore: store)
        return (service, store)
    }

    /// Registers a bridge through the service (so it lands in BOTH the service's
    /// registeredBridges map and the state store) and waits for discovery.
    private func registerAndDiscover(
        _ bridge: FakeSmartHomeBridge,
        deviceID: DeviceID,
        in service: DeviceService
    ) async {
        service.registerBridge(bridge)
        await waitUntil { service.stateStore.device(id: deviceID) != nil }
    }

    // MARK: - Forwarding

    func testSendForwardsToBridgeWhenReachable() async throws {
        let (service, store) = makeService()
        let bridgeID = BridgeID("test")
        let device = TestSmartDevice(reachability: .reachable, bridgeID: bridgeID)
        let bridge = FakeSmartHomeBridge(id: bridgeID, devices: [device])
        await registerAndDiscover(bridge, deviceID: device.id, in: service)

        try await service.setPower(true, deviceID: device.id)

        let executed = await bridge.executedActions
        XCTAssertEqual(executed.count, 1)
        XCTAssertEqual(executed.first?.capabilityID, .onOff)
        XCTAssertTrue(store.controlState(for: device).isPowered)

        await service.unregisterBridge(bridgeID)
    }

    // MARK: - Error branches

    func testSendThrowsWhenDeviceUnreachable() async throws {
        let (service, _) = makeService()
        let bridgeID = BridgeID("test")
        let device = TestSmartDevice(reachability: .unreachable, bridgeID: bridgeID)
        let bridge = FakeSmartHomeBridge(id: bridgeID, devices: [device])
        await registerAndDiscover(bridge, deviceID: device.id, in: service)

        await assertThrowsAppError(
            { try await service.setPower(true, deviceID: device.id) },
            expected: { if case .deviceUnreachable = $0 { return true }; return false }
        )

        // The action never reached the bridge.
        let executed = await bridge.executedActions
        XCTAssertTrue(executed.isEmpty)

        await service.unregisterBridge(bridgeID)
    }

    func testSendThrowsBridgeNotFoundWhenBridgeUnregistered() async throws {
        let (service, store) = makeService()
        let bridgeID = BridgeID("ghost")
        let device = TestSmartDevice(reachability: .reachable, bridgeID: bridgeID)
        let bridge = FakeSmartHomeBridge(id: bridgeID, devices: [device])

        // Connect the bridge to the store directly, bypassing the service so the
        // device exists but service.registeredBridges does NOT contain its bridge.
        store.connect(bridge: bridge)
        await waitUntil { store.device(id: device.id) != nil }

        await assertThrowsAppError(
            { try await service.setPower(true, deviceID: device.id) },
            expected: { if case .bridgeNotFound = $0 { return true }; return false }
        )

        await store.disconnect(bridgeID: bridgeID)
    }

    func testSendThrowsDeviceNotFoundForUnknownDevice() async throws {
        let (service, _) = makeService()
        await assertThrowsAppError(
            { try await service.setPower(true, deviceID: UUID()) },
            expected: { if case .deviceNotFound = $0 { return true }; return false }
        )
    }

    // MARK: - Local-preview short-circuit

    func testSendShortCircuitsForLocalPreviewWithoutBridge() async throws {
        let (service, store) = makeService()
        let planned = PlannedDevice(name: "Lamp", type: .light)
        store.upsertLocalPreviewDevice(for: planned, in: nil)

        // No bridge registered — a local-preview device must not require one.
        try await service.setPower(false, deviceID: planned.id)
        try await service.setBrightness(0.4, deviceID: planned.id)

        let state = store.controlState(for: store.device(id: planned.id)!)
        XCTAssertTrue(state.isPowered, "Brightness > 0 re-powers the device")
        XCTAssertEqual(state.brightness, 0.4, accuracy: 0.0001)
    }

    // MARK: - Helpers

    private func assertThrowsAppError(
        _ body: () async throws -> Void,
        expected: (AppError) -> Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await body()
            XCTFail("Expected an AppError to be thrown", file: file, line: line)
        } catch let error as AppError {
            XCTAssertTrue(expected(error), "Unexpected AppError: \(error)", file: file, line: line)
        } catch {
            XCTFail("Expected AppError, got \(error)", file: file, line: line)
        }
    }
}
