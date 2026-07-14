import XCTest
import SwiftData
@testable import Lumen

// Covers LocalDeviceService: CRUD over LocalDeviceRecord and the resulting bridge
// (re)registration, so that authored devices surface in the DeviceStateStore and
// removed ones disappear — all against a fake transport (no networking).
@MainActor
final class LocalDeviceServiceTests: XCTestCase {

    private var container: ModelContainer!

    private func makeService() -> (LocalDeviceService, DeviceService, DeviceStateStore) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let store = DeviceStateStore()
        let deviceService = DeviceService(modelContext: container.mainContext, stateStore: store)
        let service = LocalDeviceService(
            modelContext: container.mainContext,
            deviceService: deviceService,
            transportFactory: { _ in StubLocalTransport() }
        )
        return (service, deviceService, store)
    }

    private func localDevices(in store: DeviceStateStore) -> [any SmartDevice] {
        store.allDevices.filter { $0.bridgeID == .localNetwork }
    }

    func testReloadRegistersBridge() async {
        let (service, deviceService, store) = makeService()
        await service.reloadBridge()
        XCTAssertTrue(deviceService.registeredBridges.keys.contains(.localNetwork))
        XCTAssertNotNil(store.bridgeStatuses[.localNetwork])
    }

    func testAddDeviceSurfacesInStateStore() async {
        let (service, _, store) = makeService()
        service.addDevice(name: "Porch", address: "10.0.0.5", kind: .shellySwitch)

        await waitUntil { self.localDevices(in: store).count == 1 }
        let device = localDevices(in: store).first
        XCTAssertEqual(device?.displayName, "Porch")
        XCTAssertTrue(device?.supports(.onOff) ?? false)
    }

    func testAddDimmerExposesBrightness() async {
        let (service, _, store) = makeService()
        service.addDevice(name: "Hall", address: "10.0.0.6", kind: .shellyDimmer)

        await waitUntil { self.localDevices(in: store).first?.supports(.brightness) == true }
        XCTAssertTrue(localDevices(in: store).first?.supports(.onOff) ?? false)
    }

    func testDeleteDeviceRemovesFromStateStore() async throws {
        let (service, _, store) = makeService()
        service.addDevice(name: "Porch", address: "10.0.0.5", kind: .shellySwitch)
        await waitUntil { self.localDevices(in: store).count == 1 }

        let record = try XCTUnwrap(fetchRecords().first)
        service.deleteDevice(record)

        await waitUntil { self.localDevices(in: store).isEmpty }
        XCTAssertEqual(fetchRecords().count, 0)
    }

    func testSetAddressPersistsAndRepublishes() async throws {
        let (service, _, store) = makeService()
        service.addDevice(name: "Porch", address: "10.0.0.5", kind: .shellySwitch)
        await waitUntil { self.localDevices(in: store).count == 1 }

        let record = try XCTUnwrap(fetchRecords().first)
        service.setAddress("10.0.0.9", on: record)
        await waitUntil { self.fetchRecords().first?.address == "10.0.0.9" }

        // Still exactly one local device after the re-registration cycle.
        await waitUntil { self.localDevices(in: store).count == 1 }
    }

    func testSetKindSwitchesCapabilitySet() async throws {
        let (service, _, store) = makeService()
        service.addDevice(name: "Porch", address: "10.0.0.5", kind: .shellySwitch)
        await waitUntil { self.localDevices(in: store).first?.supports(.brightness) == false }

        let record = try XCTUnwrap(fetchRecords().first)
        service.setKind(.shellyDimmer, on: record)
        await waitUntil { self.localDevices(in: store).first?.supports(.brightness) == true }
    }

    private func fetchRecords() -> [LocalDeviceRecord] {
        let descriptor = FetchDescriptor<LocalDeviceRecord>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? container.mainContext.fetch(descriptor)) ?? []
    }
}

// MARK: - Stub Transport

private actor StubLocalTransport: LocalDeviceTransport {
    func apply(_ command: LocalDeviceCommand, to target: LocalTarget) async throws {}
    func read(from target: LocalTarget) async throws -> LocalDeviceReading {
        LocalDeviceReading(isOn: false)
    }
}
