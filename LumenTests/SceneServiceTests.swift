import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class SceneServiceTests: XCTestCase {

    private var container: ModelContainer!

    private func makeFixture() -> (SceneService, ModelContext) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        let stateStore = DeviceStateStore()
        let deviceService = DeviceService(modelContext: ctx, stateStore: stateStore)
        let sceneService = SceneService(modelContext: ctx, deviceService: deviceService)
        return (sceneService, ctx)
    }

    // MARK: - createScene

    func testCreateSceneInsertsIntoStore() throws {
        let (service, ctx) = makeFixture()
        let scene = try service.createScene(name: "Evening")
        let all = try ctx.fetch(FetchDescriptor<Scene>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.id, scene.id)
    }

    func testCreateSceneRejectsEmptyName() {
        let (service, _) = makeFixture()
        XCTAssertThrowsError(try service.createScene(name: "  "))
    }

    func testCreateSceneTrimsWhitespace() throws {
        let (service, _) = makeFixture()
        let scene = try service.createScene(name: "  Evening  ")
        XCTAssertEqual(scene.name, "Evening")
    }

    // MARK: - seedDefaultScenesIfNeeded

    func testSeedDefaultsCreatesFiveScenes() throws {
        let (service, ctx) = makeFixture()
        try service.seedDefaultScenesIfNeeded()
        let all = try ctx.fetch(FetchDescriptor<Scene>())
        XCTAssertEqual(all.count, 5)
    }

    func testSeedDefaultsIsIdempotent() throws {
        let (service, ctx) = makeFixture()
        try service.seedDefaultScenesIfNeeded()
        try service.seedDefaultScenesIfNeeded()
        let all = try ctx.fetch(FetchDescriptor<Scene>())
        XCTAssertEqual(all.count, 5)
    }

    func testSeedDefaultsSkipsWhenScenesExist() throws {
        let (service, ctx) = makeFixture()
        _ = try service.createScene(name: "Existing")
        try service.seedDefaultScenesIfNeeded()
        let all = try ctx.fetch(FetchDescriptor<Scene>())
        XCTAssertEqual(all.count, 1)
    }

    // MARK: - updateScene

    func testUpdateSceneRenames() throws {
        let (service, _) = makeFixture()
        let scene = try service.createScene(name: "Old")
        try service.updateScene(scene, name: "New")
        XCTAssertEqual(scene.name, "New")
    }

    func testUpdateRejectsEmptyName() throws {
        let (service, _) = makeFixture()
        let scene = try service.createScene(name: "Stable")
        XCTAssertThrowsError(try service.updateScene(scene, name: ""))
        XCTAssertEqual(scene.name, "Stable")
    }

    // MARK: - deleteScene

    func testDeleteSceneRemovesFromStore() throws {
        let (service, ctx) = makeFixture()
        let scene = try service.createScene(name: "Doomed")
        try service.deleteScene(scene)
        let all = try ctx.fetch(FetchDescriptor<Scene>())
        XCTAssertTrue(all.isEmpty)
    }

    // MARK: - execute

    func testExecuteEmptySceneRecordsExecutionEvent() async throws {
        let (service, ctx) = makeFixture()
        let scene = try service.createScene(name: "Empty")
        try await service.execute(scene)

        let events = try ctx.fetch(FetchDescriptor<ExecutionEvent>())
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events.first?.sceneID, scene.id)
        XCTAssertEqual(service.lastExecutedScene?.id, scene.id)
        XCTAssertFalse(service.isExecuting)
    }
}
