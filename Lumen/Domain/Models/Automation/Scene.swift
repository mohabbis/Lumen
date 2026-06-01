import Foundation
import SwiftData

// MARK: - Scene (@Model)

@Model
final class Scene {
    var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SceneAction.scene)
    var actions: [SceneAction]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "sparkles",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.actions = []
    }

    func asSnapshots() -> [SceneActionSnapshot] {
        actions
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { $0.asSnapshot() }
    }
}
