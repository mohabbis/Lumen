import XCTest
import SwiftData
@testable import Lumen

// Tests for the device-commissioning flow wired up in DeviceService:
// linking a discovered live device to a PlannedDevice and reversing it.
@MainActor
final class CommissioningTests: XCTestCase {

    // Retained for the test's lifetime — if the container deallocates, its
    // ModelContext resets and every fetched model instance becomes unusable.
    private var container: ModelContainer!

    private func makeFixture() throws -> (service: DeviceService, room: Room, ctx: ModelContext) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        let service = DeviceService(modelContext: ctx, stateStore: DeviceStateStore())

        let home = Home(name: "Test Home", isPrimary: true)
        let room = Room(name: "Living Room", type: .other)
        room.home = home
        home.rooms.append(room)
        ctx.insert(home)
        try ctx.save()

        return (service, room, ctx)
    }

    func testCommissionLinksLiveDevice() throws {
        let (service, room, _) = try makeFixture()
        let planned = try service.addPlannedDevice(name: "Lamp", type: .light, to: room)
        XCTAssertFalse(planned.isCommissioned)

        let liveID = UUID()
        try service.commission(plannedDevice: planned, liveDeviceID: liveID, bridgeID: .homeKit)

        XCTAssertEqual(planned.liveDeviceID, liveID)
        XCTAssertTrue(planned.isInstalled)
        XCTAssertTrue(planned.isCommissioned)
        XCTAssertEqual(planned.bridgeID, .homeKit)
        XCTAssertEqual(planned.planningStage, .installed)
    }

    func testUncommissionedListExcludesLinkedDevices() throws {
        let (service, room, _) = try makeFixture()
        let planned = try service.addPlannedDevice(name: "Lamp", type: .light, to: room)

        XCTAssertEqual(try service.uncommissionedPlannedDevices().count, 1)
        try service.commission(plannedDevice: planned, liveDeviceID: UUID(), bridgeID: .homeKit)
        XCTAssertTrue(try service.uncommissionedPlannedDevices().isEmpty)
    }

    func testLookupPlannedDeviceByLiveID() throws {
        let (service, room, _) = try makeFixture()
        let planned = try service.addPlannedDevice(name: "Lamp", type: .light, to: room)
        let liveID = UUID()
        try service.commission(plannedDevice: planned, liveDeviceID: liveID, bridgeID: .homeKit)

        XCTAssertEqual(try service.plannedDevice(forLiveDeviceID: liveID)?.id, planned.id)
        XCTAssertNil(try service.plannedDevice(forLiveDeviceID: UUID()))
    }

    func testDecommissionReversesCommissioning() throws {
        let (service, room, _) = try makeFixture()
        let planned = try service.addPlannedDevice(name: "Lamp", type: .light, to: room)
        try service.commission(plannedDevice: planned, liveDeviceID: UUID(), bridgeID: .homeKit)

        try service.decommission(plannedDevice: planned)

        XCTAssertNil(planned.liveDeviceID)
        XCTAssertFalse(planned.isInstalled)
        XCTAssertFalse(planned.isCommissioned)
        XCTAssertEqual(planned.planningStage, .planned)
        XCTAssertEqual(try service.uncommissionedPlannedDevices().count, 1)
    }
}
