import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class LumenSuggestionConsentTests: XCTestCase {

    private var container: ModelContainer!

    override func setUp() async throws {
        container = PersistenceCoordinator.makeInMemoryContainer()
    }

    override func tearDown() async throws {
        container = nil
    }

    func testSceneForApprovalMatchesCaseInsensitively() throws {
        let ctx = container.mainContext
        let evening = Scene(name: "Evening", iconName: "moon.stars.fill")
        let morning = Scene(name: "Morning", iconName: "sunrise.fill")
        ctx.insert(evening)
        ctx.insert(morning)
        try ctx.save()

        let scenes = try ctx.fetch(FetchDescriptor<Scene>())
        let matched = LumenSuggestionConsent.sceneForApproval(suggestedName: "evening", in: scenes)

        XCTAssertEqual(matched?.id, evening.id)
    }

    func testSceneForApprovalReturnsNilWhenMissing() {
        let scenes = [Scene(name: "Sleep", iconName: "moon.zzz.fill")]
        XCTAssertNil(LumenSuggestionConsent.sceneForApproval(suggestedName: "Evening", in: scenes))
    }

    func testSceneForApprovalReturnsNilForEmptyOrNilName() {
        let scenes = [Scene(name: "Evening", iconName: "moon.stars.fill")]
        XCTAssertNil(LumenSuggestionConsent.sceneForApproval(suggestedName: nil, in: scenes))
        XCTAssertNil(LumenSuggestionConsent.sceneForApproval(suggestedName: "   ", in: scenes))
    }
}
