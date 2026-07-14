import Foundation
import SwiftData

// MARK: - Versioned Schema V1

enum LumenSchemaV1: VersionedSchema {
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

enum LumenSchemaV2: VersionedSchema {
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

enum LumenSchemaV3: VersionedSchema {
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

// MARK: - Versioned Schema V4

enum LumenSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)

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
        LocalDeviceRecord.self,    // new in V4 — local-network device authoring records
    ]
}

// MARK: - Migration Plan

enum LumenSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        LumenSchemaV1.self,
        LumenSchemaV2.self,
        LumenSchemaV3.self,
        LumenSchemaV4.self,
    ]

    static var stages: [MigrationStage] = [
        // V1 → V2: add ExecutionEvent model.
        MigrationStage.lightweight(
            fromVersion: LumenSchemaV1.self,
            toVersion:   LumenSchemaV2.self
        ),
        // V2 → V3: drop @Attribute(.unique) from all id fields for CloudKit compatibility.
        // Note: Home.latitude and Home.longitude (optional Double, added later) are handled
        // by SwiftData's inferred migration — nullable column additions don't require a
        // new schema version.
        MigrationStage.lightweight(
            fromVersion: LumenSchemaV2.self,
            toVersion:   LumenSchemaV3.self
        ),
        // V3 → V4: add LocalDeviceRecord model (a new table — additive/lightweight).
        MigrationStage.lightweight(
            fromVersion: LumenSchemaV3.self,
            toVersion:   LumenSchemaV4.self
        ),
    ]
}
