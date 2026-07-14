import Foundation
import Observation

// MARK: - Scene View Model

@MainActor
@Observable
final class SceneViewModel {

    private let sceneService: SceneService

    var isShowingAddScene = false
    var executingSceneID: UUID?
    var pendingScene: Scene?
    var editingScene: Scene?
    var error: (any Error)?

    init(sceneService: SceneService) {
        self.sceneService = sceneService
    }

    // MARK: - Derived State

    var isExecuting: Bool { sceneService.isExecuting }
    var lastExecuted: Scene? { sceneService.lastExecutedScene }

    // MARK: - Actions

    func createScene(name: String, iconName: String = "sparkles") {
        do {
            try sceneService.createScene(name: name, iconName: iconName)
            isShowingAddScene = false
        } catch {
            self.error = error
        }
    }

    // MARK: - Approval flow

    func requestApproval(_ scene: Scene) {
        pendingScene = scene
    }

    func cancelPending() {
        pendingScene = nil
    }

    func confirmPending() {
        guard let scene = pendingScene else { return }
        pendingScene = nil
        execute(scene)
    }

    func execute(_ scene: Scene) {
        executingSceneID = scene.id
        Task {
            do {
                try await sceneService.execute(scene)
            } catch {
                self.error = error
            }
            executingSceneID = nil
        }
    }

    func deleteScene(_ scene: Scene) {
        do { try sceneService.deleteScene(scene) }
        catch { self.error = error }
    }

    func toggleFavorite(_ scene: Scene) {
        do { try sceneService.updateScene(scene, isFavorite: !scene.isFavorite) }
        catch { self.error = error }
    }

    func updateScene(
        _ scene: Scene,
        name: String? = nil,
        geofenceTrigger: GeofenceTrigger? = nil
    ) {
        do {
            try sceneService.updateScene(scene, name: name, geofenceTrigger: geofenceTrigger)
        } catch {
            self.error = error
        }
    }

    /// Sets (minutes since midnight) or clears (nil) a scene's daily schedule.
    func setSchedule(minutesSinceMidnight: Int?, on scene: Scene) {
        do {
            try sceneService.setSchedule(minutesSinceMidnight: minutesSinceMidnight, on: scene)
        } catch {
            self.error = error
        }
    }

    func addAction(
        to scene: Scene,
        deviceID: UUID,
        capabilityID: CapabilityID,
        payload: ActionPayload
    ) {
        do {
            try sceneService.addAction(
                to: scene,
                deviceID: deviceID,
                capabilityID: capabilityID,
                payload: payload
            )
        } catch {
            self.error = error
        }
    }

    func removeAction(_ action: SceneAction, from scene: Scene) {
        do {
            try sceneService.removeAction(action, from: scene)
        } catch {
            self.error = error
        }
    }
}
