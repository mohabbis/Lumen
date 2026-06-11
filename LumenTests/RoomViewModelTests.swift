import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class RoomViewModelTests: XCTestCase {

    private var container: ModelContainer!

    private func makeFixture() throws -> (RoomViewModel, HomeService, Home) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        let homeService = HomeService(modelContext: ctx)
        let stateStore = DeviceStateStore()
        let deviceService = DeviceService(modelContext: ctx, stateStore: stateStore)
        let home = try homeService.createHome(name: "Test Home")
        let vm = RoomViewModel(
            homeService: homeService,
            deviceService: deviceService,
            stateStore: stateStore
        )
        return (vm, homeService, home)
    }

    // MARK: - rooms

    func testRoomsEmptyInitially() throws {
        let (vm, _, _) = try makeFixture()
        XCTAssertTrue(vm.rooms.isEmpty)
    }

    func testRoomsSortedAlphabetically() throws {
        let (vm, service, home) = try makeFixture()
        _ = try service.addRoom(to: home, name: "Zebra",  type: .other)
        _ = try service.addRoom(to: home, name: "Apple",  type: .other)
        _ = try service.addRoom(to: home, name: "Mango",  type: .other)

        XCTAssertEqual(vm.rooms.map(\.name), ["Apple", "Mango", "Zebra"])
    }

    // MARK: - addRoom

    func testAddRoomDismissesSheet() throws {
        let (vm, _, _) = try makeFixture()
        vm.isShowingAddRoom = true
        vm.addRoom(name: "Kitchen", type: .other, level: nil)
        XCTAssertFalse(vm.isShowingAddRoom)
        XCTAssertEqual(vm.rooms.count, 1)
    }

    func testAddRoomSurfacesEmptyNameError() throws {
        let (vm, _, _) = try makeFixture()
        vm.addRoom(name: "  ", type: .other, level: nil)
        XCTAssertNotNil(vm.error)
        XCTAssertEqual(vm.rooms.count, 0)
    }

    // MARK: - updateRoom

    func testUpdateRoomRenames() throws {
        let (vm, service, home) = try makeFixture()
        let room = try service.addRoom(to: home, name: "Old Name", type: .other)
        vm.updateRoom(room, name: "New Name", type: .kitchen)
        XCTAssertEqual(room.name, "New Name")
        XCTAssertEqual(room.type, .kitchen)
    }

    // MARK: - deleteRoom

    func testDeleteRoomRemovesIt() throws {
        let (vm, service, home) = try makeFixture()
        let room = try service.addRoom(to: home, name: "Kitchen", type: .other)
        vm.deleteRoom(room)
        XCTAssertEqual(vm.rooms.count, 0)
    }

    // MARK: - device CRUD

    func testAddDeviceAttachesToRoom() throws {
        let (vm, service, home) = try makeFixture()
        let room = try service.addRoom(to: home, name: "Lounge", type: .other)
        vm.addDevice(name: "Lamp", type: .light, to: room)
        XCTAssertEqual(room.plannedDevices.count, 1)
        XCTAssertEqual(room.plannedDevices.first?.name, "Lamp")
    }

    func testAddDeviceSurfacesEmptyNameError() throws {
        let (vm, service, home) = try makeFixture()
        let room = try service.addRoom(to: home, name: "Lounge", type: .other)
        vm.addDevice(name: "", type: .light, to: room)
        XCTAssertNotNil(vm.error)
        XCTAssertEqual(room.plannedDevices.count, 0)
    }

    func testDeleteDeviceRemovesIt() throws {
        let (vm, service, home) = try makeFixture()
        let room = try service.addRoom(to: home, name: "Lounge", type: .other)
        vm.addDevice(name: "Lamp", type: .light, to: room)
        let device = try XCTUnwrap(room.plannedDevices.first)
        vm.deleteDevice(device)
        XCTAssertEqual(room.plannedDevices.count, 0)
    }
}
