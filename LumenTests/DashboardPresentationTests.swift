import CoreLocation
import XCTest
@testable import Lumen

final class DashboardPresentationTests: XCTestCase {

    func testDashboardSetupPromptsForFirstRoom() {
        let presentation = DashboardSetupPresentation(
            roomCount: 0,
            installedDeviceCount: 0,
            sceneCount: 5
        )

        XCTAssertTrue(presentation.shouldShow)
        XCTAssertEqual(presentation.title, "Start with one room")
        XCTAssertEqual(presentation.actionTitle, "Add first room")
        XCTAssertEqual(presentation.steps.first(where: { $0.id == "room" })?.state, .current)
        XCTAssertEqual(presentation.steps.first(where: { $0.id == "device" })?.state, .pending)
        XCTAssertEqual(presentation.steps.first(where: { $0.id == "scene" })?.state, .complete)
    }

    func testDashboardSetupHidesAfterRoomsExist() {
        let presentation = DashboardSetupPresentation(
            roomCount: 2,
            installedDeviceCount: 1,
            sceneCount: 5
        )

        XCTAssertFalse(presentation.shouldShow)
        XCTAssertEqual(presentation.steps.first(where: { $0.id == "room" })?.state, .complete)
        XCTAssertEqual(presentation.steps.first(where: { $0.id == "device" })?.state, .complete)
    }

    func testStatusOverlayPresentationForHomeAndAway() {
        let home = StatusOverlayPresentation(isAtHome: true)
        XCTAssertEqual(home.title, "Welcome home")
        XCTAssertEqual(home.iconName, "house.fill")
        XCTAssertEqual(home.tintHex, "#C49A6C")

        let away = StatusOverlayPresentation(isAtHome: false)
        XCTAssertEqual(away.title, "Away mode")
        XCTAssertEqual(away.iconName, "location.fill")
        XCTAssertEqual(away.tintHex, "#FFFFFF")
        XCTAssertEqual(away.tintOpacity, 0.72)
    }

    func testLocationPermissionPresentationOnlyShowsBlockedStates() {
        XCTAssertNil(LocationPermissionPresentation(status: .authorizedWhenInUse))
        XCTAssertNil(LocationPermissionPresentation(status: .notDetermined))

        let denied = LocationPermissionPresentation(status: .denied)
        XCTAssertEqual(denied?.title, "Location is off")
        XCTAssertEqual(denied?.actionTitle, "Open Settings")

        let restricted = LocationPermissionPresentation(status: .restricted)
        XCTAssertEqual(restricted?.title, "Location is off")
    }
}
