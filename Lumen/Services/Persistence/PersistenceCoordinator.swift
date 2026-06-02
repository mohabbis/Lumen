import Foundation
import SwiftData

// MARK: - Persistence Coordinator

enum PersistenceCoordinator {

    // MARK: - Configuration

    /// CloudKit cross-device sync. Keep OFF until the `iCloud.com.muhome.app`
    /// container actually exists in the Apple Developer portal (iCloud Containers)
    /// AND the App ID has the iCloud/CloudKit capability enabled.
    ///
    /// Why this gate exists: `cloudKitDatabase: .automatic` initializes the CloudKit
    /// mirroring stack synchronously during `ModelContainer` creation — which runs on
    /// the main thread in `MuhomeApp.init()`. If the named container doesn't exist
    /// server-side, that setup blocks the main thread and the app launches to a black
    /// screen (process alive, UI never drawn — not a crash). Flip this to `true` only
    /// once the container is provisioned; the app works fully local-only until then.
    static let enableCloudKitSync = false

    // MARK: - Production Container

    static func makeContainer() -> ModelContainer {
        // Ensure Application Support directory exists before SwiftData tries to
        // create default.store there. Without this, CoreData logs sandbox errors
        // on first launch because the directory doesn't yet exist.
        let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(
            at: appSupport,
            withIntermediateDirectories: true
        )

        let schema = Schema(
            MuhomeSchemaV4.models,
            version: MuhomeSchemaV4.versionIdentifier
        )

        // When CloudKit is enabled, prefer the synced store but degrade to local-only
        // if its container can't initialize (unprovisioned container, signed-out iCloud,
        // capability off) rather than crashing. When disabled, go straight to local.
        if enableCloudKitSync,
           let synced = try? makeContainer(schema: schema, cloudKit: .automatic) {
            return synced
        }

        do {
            return try makeContainer(schema: schema, cloudKit: .none)
        } catch {
            reportFatalError(error)
            fatalError("[Muhome] Unrecoverable persistence failure: \(error)")
        }
    }

    private static func makeContainer(
        schema: Schema,
        cloudKit: ModelConfiguration.CloudKitDatabase
    ) throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: cloudKit
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: MuhomeSchemaMigrationPlan.self,
            configurations: config
        )
    }

    // MARK: - In-Memory Container (Previews & Tests)

    static func makeInMemoryContainer() -> ModelContainer {
        let schema = Schema(
            MuhomeSchemaV4.models,
            version: MuhomeSchemaV4.versionIdentifier
        )
        // cloudKitDatabase: .none is required — without it SwiftData defaults to
        // .automatic, detects the host app's iCloud entitlement, and tries to set up
        // CloudKit mirroring against a container that may not exist, which aborts.
        // In-memory stores (tests & previews) must never touch CloudKit.
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        return try! ModelContainer(for: schema, configurations: config)
    }

    // MARK: - Private

    private static func reportFatalError(_ error: Error) {
        // Forward to crash reporter (Crashlytics / Sentry) before aborting.
        print("[Muhome] FATAL: \(error)")
    }
}
