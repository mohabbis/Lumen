import Foundation
import SwiftData

// MARK: - Versioned Schema V1

enum MuhomeSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Home.self,
        Room.self,
        Zone.self,
        PlannedDevice.self,
        Scene.self,
        SceneAction.self,
        RemoteProfile.self,
        IRCommand.self,
    ]
}

// MARK: - Versioned Schema V2

enum MuhomeSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] = [
        Home.self,
        Room.self,
        Zone.self,
        PlannedDevice.self,
        Scene.self,
        SceneAction.self,
        RemoteProfile.self,
        IRCommand.self,
        ExecutionEvent.self,    // new in V2
    ]
}

// MARK: - Versioned Schema V3

enum MuhomeSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    // Identical model set to V2 — the only change is dropping @Attribute(.unique)
    // from all id fields, which is required for CloudKit sync compatibility.
    static var models: [any PersistentModel.Type] = [
        Home.self,
        Room.self,
        Zone.self,
        PlannedDevice.self,
        Scene.self,
        SceneAction.self,
        RemoteProfile.self,
        IRCommand.self,
        ExecutionEvent.self,
    ]
}

// MARK: - Migration Plan

enum MuhomeSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        MuhomeSchemaV1.self,
        MuhomeSchemaV2.self,
        MuhomeSchemaV3.self,
    ]

    static var stages: [MigrationStage] = [
        // V1 → V2: add ExecutionEvent model.
        MigrationStage.lightweight(
            fromVersion: MuhomeSchemaV1.self,
            toVersion:   MuhomeSchemaV2.self
        ),
        // V2 → V3: drop @Attribute(.unique) from all id fields for CloudKit compatibility.
        // Note: Home.latitude and Home.longitude (optional Double, added later) are handled
        // by SwiftData's inferred migration — nullable column additions don't require a
        // new schema version.
        MigrationStage.lightweight(
            fromVersion: MuhomeSchemaV2.self,
            toVersion:   MuhomeSchemaV3.self
        ),
    ]
}
