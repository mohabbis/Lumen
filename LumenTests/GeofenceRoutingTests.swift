import XCTest
import SwiftData
@testable import Lumen

@MainActor
final class GeofenceRoutingTests: XCTestCase {

    private var container: ModelContainer!

    private func makeScene(name: String, trigger: GeofenceTrigger) -> Scene {
        let container = self.container ?? PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let scene = Scene(name: name)
        scene.geofenceTrigger = trigger
        container.mainContext.insert(scene)
        return scene
    }

    private func event(_ type: GeofenceEvent.EventType) -> GeofenceEvent {
        GeofenceEvent(type: type, timestamp: Date())
    }

    // MARK: - scenesMatching

    func testArrivalMatchesOnlyArrivalScenes() {
        let arrivalScene = makeScene(name: "Welcome", trigger: .onArrival)
        let departureScene = makeScene(name: "Lock up", trigger: .onDeparture)
        let neutralScene = makeScene(name: "Movie", trigger: .none)

        let matches = SceneService.scenesMatching(
            event: event(.arrival),
            in: [arrivalScene, departureScene, neutralScene]
        )

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.id, arrivalScene.id)
    }

    func testDepartureMatchesOnlyDepartureScenes() {
        let arrivalScene = makeScene(name: "Welcome", trigger: .onArrival)
        let departureScene = makeScene(name: "Lock up", trigger: .onDeparture)
        let neutralScene = makeScene(name: "Movie", trigger: .none)

        let matches = SceneService.scenesMatching(
            event: event(.departure),
            in: [arrivalScene, departureScene, neutralScene]
        )

        XCTAssertEqual(matches.count, 1)
        XCTAssertEqual(matches.first?.id, departureScene.id)
    }

    func testNoMatchesWhenAllScenesAreNeutral() {
        let movie = makeScene(name: "Movie", trigger: .none)
        let custom = makeScene(name: "Custom", trigger: .none)

        XCTAssertTrue(
            SceneService.scenesMatching(event: event(.arrival),   in: [movie, custom]).isEmpty
        )
        XCTAssertTrue(
            SceneService.scenesMatching(event: event(.departure), in: [movie, custom]).isEmpty
        )
    }

    func testMultipleScenesWithSameTriggerAllMatch() {
        let s1 = makeScene(name: "Lights On", trigger: .onArrival)
        let s2 = makeScene(name: "Music On", trigger: .onArrival)
        let s3 = makeScene(name: "Lights Off", trigger: .onDeparture)

        let matches = SceneService.scenesMatching(
            event: event(.arrival),
            in: [s1, s2, s3]
        )

        XCTAssertEqual(matches.count, 2)
        XCTAssertTrue(matches.contains(where: { $0.id == s1.id }))
        XCTAssertTrue(matches.contains(where: { $0.id == s2.id }))
    }

    // MARK: - eventTypeString

    func testEventTypeStringForArrival() {
        XCTAssertEqual(SceneService.eventTypeString(for: event(.arrival)), "arrival")
    }

    func testEventTypeStringForDeparture() {
        XCTAssertEqual(SceneService.eventTypeString(for: event(.departure)), "departure")
    }
}
