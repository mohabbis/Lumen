import XCTest
@testable import Lumen

final class TransitionWarningTests: XCTestCase {

    private func makeDate(hour: Int, minute: Int) -> Date {
        var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        c.hour = hour
        c.minute = minute
        c.second = 0
        return Calendar.current.date(from: c) ?? Date()
    }

    func testUpcomingWarningsExcludePastTransitions() {
        let schedule = TransitionSchedule(
            leadMinutes: 15,
            referenceDate: makeDate(hour: 14, minute: 15),
            calendar: .current
        )

        let upcoming = schedule.upcomingWarnings
        XCTAssertTrue(upcoming.count >= 2, "Should have at least 2 upcoming warnings")

        let now = makeDate(hour: 14, minute: 15)
        for warning in upcoming {
            XCTAssertTrue(warning.fireDate > now, "\(warning.block.name) warning should be in the future")
        }
    }

    func testWarningsSortedByFireDate() {
        let schedule = TransitionSchedule(
            leadMinutes: 15,
            referenceDate: makeDate(hour: 10, minute: 0),
            calendar: .current
        )

        let warnings = schedule.upcomingWarnings
        for i in 1..<warnings.count {
            XCTAssertTrue(warnings[i].fireDate >= warnings[i - 1].fireDate)
        }
    }

    func testFiveMinuteLeadProducesLaterFireDates() {
        let ref = makeDate(hour: 10, minute: 0)
        let fifteen = TransitionSchedule(leadMinutes: 15, referenceDate: ref, calendar: .current)
        let five = TransitionSchedule(leadMinutes: 5, referenceDate: ref, calendar: .current)

        if let fifteenFirst = fifteen.upcomingWarnings.first,
           let fiveFirst = five.upcomingWarnings.first,
           fifteenFirst.block == fiveFirst.block {
            XCTAssertTrue(fiveFirst.fireDate > fifteenFirst.fireDate)
        }
    }

    func testZeroLeadProducesNoWarnings() {
        let schedule = TransitionSchedule(
            leadMinutes: 0,
            referenceDate: makeDate(hour: 10, minute: 0),
            calendar: .current
        )
        XCTAssertTrue(schedule.upcomingWarnings.isEmpty)
    }

    func testWarningMessageContainsBlockName() {
        let warning = TransitionWarning(
            block: .evening,
            transitionDate: makeDate(hour: 17, minute: 0),
            fireDate: makeDate(hour: 16, minute: 45),
            leadMinutes: 15
        )
        XCTAssertTrue(warning.message.contains("Evening"))
        XCTAssertTrue(warning.message.contains("15"))
    }

    func testMinutesUntilNextBlockPositive() {
        let timing = RhythmTiming(
            now: .morning,
            referenceDate: makeDate(hour: 10, minute: 0),
            calendar: .current
        )
        XCTAssertEqual(timing.minutesUntilNextBlock, 120, accuracy: 1)
    }
}
