import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class HomeViewModelTests: XCTestCase {

    private var container: ModelContainer!

    private func makeViewModel() -> (HomeViewModel, HomeService) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        let homeService = HomeService(modelContext: ctx)
        let stateStore = DeviceStateStore()
        let deviceService = DeviceService(modelContext: ctx, stateStore: stateStore)
        let vm = HomeViewModel(
            homeService: homeService,
            deviceService: deviceService,
            stateStore: stateStore
        )
        return (vm, homeService)
    }

    private func makeViewModelWithSceneService() -> (HomeViewModel, SceneService) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        let homeService = HomeService(modelContext: ctx)
        let stateStore = DeviceStateStore()
        let deviceService = DeviceService(modelContext: ctx, stateStore: stateStore)
        let sceneService = SceneService(modelContext: ctx, deviceService: deviceService)
        let vm = HomeViewModel(
            homeService: homeService,
            deviceService: deviceService,
            stateStore: stateStore,
            sceneService: sceneService
        )
        return (vm, sceneService)
    }

    func testHasHomeFalseBeforeCreate() {
        let (vm, _) = makeViewModel()
        XCTAssertFalse(vm.hasHome)
        XCTAssertNil(vm.home)
        XCTAssertEqual(vm.rooms.count, 0)
    }

    func testCreateHomePopulatesViewModel() {
        let (vm, _) = makeViewModel()
        vm.createHome(name: "Test")
        XCTAssertTrue(vm.hasHome)
        XCTAssertEqual(vm.home?.name, "Test")
    }

    func testCreateHomeDismissesOnboarding() {
        let (vm, _) = makeViewModel()
        vm.isShowingOnboarding = true
        vm.createHome(name: "Test")
        XCTAssertFalse(vm.isShowingOnboarding)
    }

    func testRoomsSortedAlphabetically() throws {
        let (vm, service) = makeViewModel()
        vm.createHome(name: "Test")
        let home = try XCTUnwrap(service.primaryHome)
        _ = try service.addRoom(to: home, name: "Zebra", type: .other)
        _ = try service.addRoom(to: home, name: "Apple", type: .other)
        _ = try service.addRoom(to: home, name: "Mango", type: .other)

        XCTAssertEqual(vm.rooms.map(\.name), ["Apple", "Mango", "Zebra"])
    }

    func testRenameHomePersists() throws {
        let (vm, service) = makeViewModel()
        vm.createHome(name: "Old")
        vm.renameHome(to: "New")
        XCTAssertEqual(service.primaryHome?.name, "New")
    }

    func testRenameHomeIgnoresWhitespaceOnly() {
        let (vm, service) = makeViewModel()
        vm.createHome(name: "Original")
        vm.renameHome(to: "   ")
        XCTAssertEqual(service.primaryHome?.name, "Original")
    }

    func testAddRoomDismissesSheet() {
        let (vm, _) = makeViewModel()
        vm.createHome(name: "Test")
        vm.isShowingAddRoom = true
        vm.addRoom(name: "Kitchen", type: .other, level: nil)
        XCTAssertFalse(vm.isShowingAddRoom)
        XCTAssertEqual(vm.rooms.count, 1)
    }

    func testAddRoomWithoutHomeIsNoOp() {
        let (vm, _) = makeViewModel()
        vm.addRoom(name: "Kitchen", type: .other, level: nil)
        XCTAssertEqual(vm.rooms.count, 0)
        XCTAssertNil(vm.error)
    }

    // MARK: - executeScene

    func testExecuteSceneWithoutSceneServiceIsNoOp() async {
        let (vm, _) = makeViewModel()  // sceneService nil
        // Construct a scene we'll never execute; it just needs to compile.
        let scene = Scene(name: "Ignored")
        await vm.executeScene(scene)
        XCTAssertNil(vm.error)
    }

    func testExecuteSceneSurfacesErrorWhenSceneFails() async throws {
        let (vm, sceneService) = makeViewModelWithSceneService()
        let scene = try sceneService.createScene(name: "Failing")
        // Action targets a deviceID that no bridge has registered — DeviceService.send
        // will throw .deviceNotFound, which SceneService re-throws to the caller.
        _ = try sceneService.addAction(
            to: scene,
            deviceID: UUID(),
            capabilityID: CapabilityID("power"),
            payload: .bool(true)
        )

        XCTAssertNil(vm.error)
        await vm.executeScene(scene)
        XCTAssertNotNil(vm.error)
    }
}
