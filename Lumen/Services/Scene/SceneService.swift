import Foundation
import SwiftData
import Observation

// MARK: - Scene Service

@MainActor
@Observable
final class SceneService {

    private let modelContext: ModelContext
    private let deviceService: DeviceService

    private(set) var isExecuting = false
    private(set) var lastExecutedScene: Scene?
    private(set) var lastError: (any Error)?

    init(modelContext: ModelContext, deviceService: DeviceService) {
        self.modelContext = modelContext
        self.deviceService = deviceService
    }

    // MARK: - Scene CRUD

    @discardableResult
    func createScene(name: String, iconName: String = "sparkles") throws -> Scene {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            throw AppError.invalidConfiguration(reason: "Scene name cannot be empty.")
        }
        let scene = Scene(name: cleaned, iconName: iconName)
        modelContext.insert(scene)
        try modelContext.save()
        return scene
    }

    func seedDefaultScenesIfNeeded() throws {
        let descriptor = FetchDescriptor<Scene>()
        guard try modelContext.fetchCount(descriptor) == 0 else { return }

        let defaults: [(String, String)] = [
            ("Morning", "sunrise.fill"),
            ("Evening", "moon.stars.fill"),
            ("Movie Night", "popcorn.fill"),
            ("Sleep", "moon.zzz.fill"),
            ("Away", "house.slash.fill")
        ]

        for (index, item) in defaults.enumerated() {
            let scene = Scene(name: item.0, iconName: item.1, sortOrder: index)
            scene.isFavorite = index < 3
            modelContext.insert(scene)
        }
        try modelContext.save()
    }

    func updateScene(_ scene: Scene, name: String? = nil, iconName: String? = nil, isFavorite: Bool? = nil) throws {
        if let name {
            let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleaned.isEmpty else {
                throw AppError.invalidConfiguration(reason: "Scene name cannot be empty.")
            }
            scene.name = cleaned
        }
        if let iconName { scene.iconName = iconName }
        if let isFavorite { scene.isFavorite = isFavorite }
        scene.updatedAt = Date()
        try modelContext.save()
    }

    func deleteScene(_ scene: Scene) throws {
        modelContext.delete(scene)
        try modelContext.save()
    }

    @discardableResult
    func addAction(
        to scene: Scene,
        deviceID: UUID,
        capabilityID: CapabilityID,
        payload: ActionPayload
    ) throws -> SceneAction {
        let action = SceneAction(
            deviceID: deviceID,
            capabilityID: capabilityID,
            payload: payload,
            sortOrder: scene.actions.count
        )
        action.scene = scene
        scene.actions.append(action)
        scene.updatedAt = Date()
        try modelContext.save()
        return action
    }

    func removeAction(_ action: SceneAction, from scene: Scene) throws {
        modelContext.delete(action)
        scene.updatedAt = Date()
        try modelContext.save()
    }

    // MARK: - Execution

    func execute(_ scene: Scene) async throws {
        isExecuting = true
        lastError = nil
        defer { isExecuting = false }

        let snapshots = scene.asSnapshots()
        if snapshots.isEmpty {
            let affected = deviceService.applyLocalScenePreset(named: scene.name)
            let event = ExecutionEvent(
                sceneID: scene.id,
                sceneName: scene.name,
                succeeded: affected,
                failed: 0
            )
            modelContext.insert(event)
            scene.updatedAt = Date()
            try modelContext.save()
            lastExecutedScene = scene
            return
        }

        var succeeded = 0
        var failed = 0
        var lastFailure: (any Error)?

        await withTaskGroup(of: Result<Void, any Error>.self) { group in
            for snapshot in snapshots {
                group.addTask {
                    do {
                        try await self.deviceService.send(action: snapshot)
                        return .success(())
                    } catch {
                        return .failure(error)
                    }
                }
            }

            for await result in group {
                switch result {
                case .success:         succeeded += 1
                case .failure(let e):  failed += 1; lastFailure = e
                }
            }
        }

        let event = ExecutionEvent(
            sceneID: scene.id,
            sceneName: scene.name,
            succeeded: succeeded,
            failed: failed
        )
        modelContext.insert(event)

        scene.updatedAt = Date()
        try modelContext.save()

        lastExecutedScene = scene

        if failed > 0 && succeeded == 0 {
            let err = lastFailure ?? AppError.sceneExecutionFailed(underlying: AppError.sceneNotFound(scene.id))
            lastError = err
            throw err
        }
        if failed > 0 {
            let err = AppError.sceneExecutionPartialFailure(succeeded: succeeded, failed: failed)
            lastError = err
            throw err
        }
    }
}
