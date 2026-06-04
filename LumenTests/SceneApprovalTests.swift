import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class SceneApprovalTests: XCTestCase {

    private var container: ModelContainer!

    private func makeFixture() -> (SceneViewModel, SceneService, ModelContext) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        let stateStore = DeviceStateStore()
        let deviceService = DeviceService(modelContext: ctx, stateStore: stateStore)
        let sceneService = SceneService(modelContext: ctx, deviceService: deviceService)
        let vm = SceneViewModel(sceneService: sceneService)
        return (vm, sceneService, ctx)
    }

    // MARK: - Approval flow

    func testRequestApprovalSetsPendingScene() throws {
        let (vm, service, _) = makeFixture()
        let scene = try service.createScene(name: "Test")

        XCTAssertNil(vm.pendingScene)
        vm.requestApproval(scene)
        XCTAssertEqual(vm.pendingScene?.id, scene.id)
    }

    func testCancelPendingClearsWithoutExecuting() throws {
        let (vm, service, ctx) = makeFixture()
        let scene = try service.createScene(name: "Test")

        vm.requestApproval(scene)
        vm.cancelPending()

        XCTAssertNil(vm.pendingScene)
        let events = try ctx.fetch(FetchDescriptor<ExecutionEvent>())
        XCTAssertTrue(events.isEmpty)
    }

    func testConfirmPendingClearsPendingScene() throws {
        let (vm, service, _) = makeFixture()
        let scene = try service.createScene(name: "Test")

        vm.requestApproval(scene)
        vm.confirmPending()

        XCTAssertNil(vm.pendingScene)
    }

    func testConfirmPendingTriggersExecution() throws {
        let (vm, service, _) = makeFixture()
        let scene = try service.createScene(name: "Test")

        vm.requestApproval(scene)
        vm.confirmPending()

        // `execute` sets `executingSceneID` synchronously before its Task block runs.
        XCTAssertEqual(vm.executingSceneID, scene.id)
    }

    func testConfirmWithNoPendingIsSafe() {
        let (vm, _, _) = makeFixture()
        vm.confirmPending() // no scene pending
        XCTAssertNil(vm.pendingScene)
        XCTAssertNil(vm.executingSceneID)
    }

    // MARK: - SceneActionDescription humanization

    func testDescriptionForPowerOn() {
        let action = SceneAction(
            deviceID: UUID(),
            capabilityID: CapabilityID("power"),
            payload: .bool(true)
        )
        let desc = SceneActionDescription(action: action)
        XCTAssertEqual(desc.capability, "Power")
        XCTAssertEqual(desc.detail, "On")
    }

    func testDescriptionForPowerOff() {
        let action = SceneAction(
            deviceID: UUID(),
            capabilityID: CapabilityID("power"),
            payload: .bool(false)
        )
        let desc = SceneActionDescription(action: action)
        XCTAssertEqual(desc.detail, "Off")
    }

    func testDescriptionForBrightnessAsPercent() {
        let action = SceneAction(
            deviceID: UUID(),
            capabilityID: CapabilityID("brightness"),
            payload: .double(0.4)
        )
        let desc = SceneActionDescription(action: action)
        XCTAssertEqual(desc.capability, "Brightness")
        XCTAssertEqual(desc.detail, "40%")
    }

    func testDescriptionForTemperatureRendersCelsius() {
        let action = SceneAction(
            deviceID: UUID(),
            capabilityID: CapabilityID("temperature"),
            payload: .temperature(Measurement(value: 22.0, unit: .celsius))
        )
        let desc = SceneActionDescription(action: action)
        XCTAssertEqual(desc.capability, "Temperature")
        XCTAssertEqual(desc.detail, "22°C")
    }

    func testDescriptionForColorRendersGeneric() {
        let action = SceneAction(
            deviceID: UUID(),
            capabilityID: CapabilityID("color"),
            payload: .colorHSB(hue: 0.5, saturation: 0.8, brightness: 0.7)
        )
        let desc = SceneActionDescription(action: action)
        XCTAssertEqual(desc.capability, "Color")
        XCTAssertEqual(desc.detail, "Custom color")
    }

    func testDescriptionCapitalizesUnknownCapability() {
        let action = SceneAction(
            deviceID: UUID(),
            capabilityID: CapabilityID("customThing"),
            payload: .bool(true)
        )
        let desc = SceneActionDescription(action: action)
        XCTAssertEqual(desc.capability, "CustomThing")
    }
}
