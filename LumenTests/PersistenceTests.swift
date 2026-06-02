import XCTest
import SwiftData
@testable import Lumen

// Guards the persistence configuration that keeps the app from black-screening
// at launch when the iCloud CloudKit container isn't provisioned.
final class PersistenceTests: XCTestCase {

    func testCloudKitSyncIsGatedOffForBeta() {
        // `.automatic` CloudKit init runs synchronously in MuhomeApp.init(); pointing
        // it at a non-existent container hangs the main thread (black screen on launch).
        // This must stay false until iCloud.com.muhome.app exists in the portal.
        XCTAssertFalse(PersistenceCoordinator.enableCloudKitSync)
    }

    @MainActor
    func testInMemoryContainerInitializes() throws {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        XCTAssertNotNil(container.mainContext)
    }

    @MainActor
    func testSchemaRoundTripsAHome() throws {
        // Hold the container — letting it deallocate resets the context mid-test.
        let container = PersistenceCoordinator.makeInMemoryContainer()
        let ctx = container.mainContext
        ctx.insert(Home(name: "Round Trip", isPrimary: true))
        try ctx.save()

        let homes = try ctx.fetch(FetchDescriptor<Home>())
        XCTAssertEqual(homes.count, 1)
        XCTAssertEqual(homes.first?.name, "Round Trip")
    }
}
