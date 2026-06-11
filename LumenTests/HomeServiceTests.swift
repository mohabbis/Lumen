import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class HomeServiceTests: XCTestCase {

    // Retained — letting the container deallocate resets the ModelContext mid-test.
    private var container: ModelContainer!

    private func makeService() -> (HomeService, ModelContext) {
        let container = PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let ctx = container.mainContext
        return (HomeService(modelContext: ctx), ctx)
    }

    // MARK: - createHome

    func testFirstHomeIsAutoPromotedToPrimary() throws {
        let (service, _) = makeService()
        let home = try service.createHome(name: "Test")
        XCTAssertTrue(home.isPrimary)
        XCTAssertEqual(service.primaryHome?.id, home.id)
    }

    func testSecondHomeDoesNotBecomePrimary() throws {
        let (service, _) = makeService()
        let first = try service.createHome(name: "First")
        let second = try service.createHome(name: "Second")
        XCTAssertTrue(first.isPrimary)
        XCTAssertFalse(second.isPrimary)
        XCTAssertEqual(service.primaryHome?.id, first.id)
    }

    func testCreateHomeRejectsEmptyName() {
        let (service, _) = makeService()
        XCTAssertThrowsError(try service.createHome(name: "   "))
    }

    // MARK: - updateHome

    func testRenameUpdatesName() throws {
        let (service, _) = makeService()
        let home = try service.createHome(name: "Old")
        try service.updateHome(home, name: "New")
        XCTAssertEqual(home.name, "New")
    }

    func testRenameRejectsEmptyName() throws {
        let (service, _) = makeService()
        let home = try service.createHome(name: "Stable")
        XCTAssertThrowsError(try service.updateHome(home, name: ""))
        XCTAssertEqual(home.name, "Stable")
    }

    // MARK: - load

    func testLoadPromotesFirstHomeWhenNoPrimaryFlag() throws {
        let (service, ctx) = makeService()
        let orphan = Home(name: "Orphan", isPrimary: false)
        ctx.insert(orphan)
        try ctx.save()
        XCTAssertNil(service.primaryHome)

        try service.load()

        XCTAssertTrue(orphan.isPrimary)
        XCTAssertEqual(service.primaryHome?.id, orphan.id)
        XCTAssertTrue(service.isLoaded)
    }

    // MARK: - Room CRUD

    func testAddRoomAppendsToHome() throws {
        let (service, _) = makeService()
        let home = try service.createHome(name: "Test")
        let room = try service.addRoom(to: home, name: "Living Room", type: .other)
        XCTAssertTrue(home.rooms.contains(where: { $0.id == room.id }))
    }

    func testAddRoomRejectsEmptyName() throws {
        let (service, _) = makeService()
        let home = try service.createHome(name: "Test")
        XCTAssertThrowsError(try service.addRoom(to: home, name: " ", type: .other))
    }

    func testDeleteRoomRemovesFromHome() throws {
        let (service, _) = makeService()
        let home = try service.createHome(name: "Test")
        let room = try service.addRoom(to: home, name: "Bedroom", type: .other)
        try service.deleteRoom(room)
        XCTAssertFalse(home.rooms.contains(where: { $0.id == room.id }))
    }

    // MARK: - deleteHome promotion

    func testDeletingPrimaryPromotesNextHome() throws {
        let (service, _) = makeService()
        let first = try service.createHome(name: "First")
        let second = try service.createHome(name: "Second")
        XCTAssertTrue(first.isPrimary)

        try service.deleteHome(first)

        XCTAssertTrue(second.isPrimary)
        XCTAssertEqual(service.primaryHome?.id, second.id)
    }
}
