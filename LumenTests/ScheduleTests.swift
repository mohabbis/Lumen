import XCTest
import SwiftData
@testable import Lumen

// Covers the daily-schedule trigger: the pure ScheduleTiming evaluator and
// SceneService.scenesDue routing. No timers or notifications.
final class ScheduleTests: XCTestCase {

    private let calendar = Calendar(identifier: .gregorian)
    private var container: ModelContainer!

    @MainActor
    private func makeScene(name: String, minutes: Int?) -> Scene {
        let container = self.container ?? PersistenceCoordinator.makeInMemoryContainer()
        self.container = container
        let scene = Scene(name: name, scheduleMinutesSinceMidnight: minutes)
        container.mainContext.insert(scene)
        return scene
    }

    private func date(_ y: Int, _ mo: Int, _ d: Int, _ h: Int, _ mi: Int) -> Date {
        var comps = DateComponents()
        comps.year = y; comps.month = mo; comps.day = d; comps.hour = h; comps.minute = mi
        return calendar.date(from: comps)!
    }

    // MARK: - ScheduleTiming

    func testFireDateIsMidnightPlusMinutes() {
        let ref = date(2026, 7, 14, 8, 30)
        let fire = ScheduleTiming.fireDate(minutesSinceMidnight: 21 * 60, on: ref, calendar: calendar)
        XCTAssertEqual(fire, date(2026, 7, 14, 21, 0))
    }

    func testFireDateRejectsOutOfRange() {
        let ref = date(2026, 7, 14, 8, 30)
        XCTAssertNil(ScheduleTiming.fireDate(minutesSinceMidnight: -1, on: ref, calendar: calendar))
        XCTAssertNil(ScheduleTiming.fireDate(minutesSinceMidnight: 1440, on: ref, calendar: calendar))
    }

    func testDueExactlyAtFireTime() {
        let now = date(2026, 7, 14, 21, 0)
        XCTAssertTrue(ScheduleTiming.isDue(minutesSinceMidnight: 21 * 60, now: now, lastFired: nil, calendar: calendar))
    }

    func testNotDueBeforeFireTime() {
        let now = date(2026, 7, 14, 20, 59)
        XCTAssertFalse(ScheduleTiming.isDue(minutesSinceMidnight: 21 * 60, now: now, lastFired: nil, calendar: calendar))
    }

    func testDueWithinGraceButNotAfter() {
        let fire = 21 * 60
        XCTAssertTrue(ScheduleTiming.isDue(
            minutesSinceMidnight: fire, now: date(2026, 7, 14, 21, 1), lastFired: nil, grace: 120, calendar: calendar
        ))
        // 3 minutes late with a 2-minute grace → missed, does not fire stale.
        XCTAssertFalse(ScheduleTiming.isDue(
            minutesSinceMidnight: fire, now: date(2026, 7, 14, 21, 3), lastFired: nil, grace: 120, calendar: calendar
        ))
    }

    func testDoesNotRefireSameDay() {
        let fire = 21 * 60
        let firstFire = date(2026, 7, 14, 21, 0)
        XCTAssertFalse(ScheduleTiming.isDue(
            minutesSinceMidnight: fire, now: date(2026, 7, 14, 21, 1), lastFired: firstFire, grace: 120, calendar: calendar
        ))
    }

    func testFiresAgainNextDay() {
        let fire = 21 * 60
        let yesterday = date(2026, 7, 13, 21, 0)
        XCTAssertTrue(ScheduleTiming.isDue(
            minutesSinceMidnight: fire, now: date(2026, 7, 14, 21, 0), lastFired: yesterday, grace: 120, calendar: calendar
        ))
    }

    func testMidnightSchedule() {
        let now = date(2026, 7, 14, 0, 0)
        XCTAssertTrue(ScheduleTiming.isDue(minutesSinceMidnight: 0, now: now, lastFired: nil, calendar: calendar))
    }

    // MARK: - scenesDue routing

    @MainActor
    func testScenesDueFiltersByScheduleAndLastFired() {
        let scheduled = makeScene(name: "Wind-down", minutes: 21 * 60)
        let unscheduled = makeScene(name: "Movie Night", minutes: nil)
        let alreadyFired = makeScene(name: "Morning", minutes: 21 * 60)

        let now = date(2026, 7, 14, 21, 0)
        let lastFired = [alreadyFired.id: now]

        let due = SceneService.scenesDue(
            at: now,
            in: [scheduled, unscheduled, alreadyFired],
            lastFired: lastFired,
            grace: 120,
            calendar: calendar
        )

        XCTAssertEqual(due.map(\.id), [scheduled.id])
    }
}
