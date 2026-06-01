import Foundation
import Observation

// MARK: - Scene View Model

@MainActor
@Observable
final class SceneViewModel {

    private let sceneService: SceneService

    var isShowingAddScene = false
    var executingSceneID: UUID?
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
}
