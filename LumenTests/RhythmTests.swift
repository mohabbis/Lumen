import XCTest
@testable import Lumen

// Pure math for the Now/Next rhythm card. Calendar is pinned to UTC so the
// numbers don't shift with the test runner's locale or timezone.
final class RhythmTests: XCTestCase {

    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }()

    private func date(year: Int = 2026, month: Int = 6, day: Int = 3, hour: Int, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return calendar.date(from: components)!
    }

    // MARK: - TimeOfDay.nextBlock

    func testNextBlockCyclesThroughDay() {
        XCTAssertEqual(TimeOfDay.dawn.nextBlock,      .morning)
        XCTAssertEqual(TimeOfDay.morning.nextBlock,   .afternoon)
        XCTAssertEqual(TimeOfDay.afternoon.nextBlock, .evening)
        XCTAssertEqual(TimeOfDay.evening.nextBlock,   .night)
        XCTAssertEqual(TimeOfDay.night.nextBlock,     .dawn)
    }

    // MARK: - RhythmTiming.progress

    func testProgressAtStartOfBlockIsZero() {
        let timing = RhythmTiming(now: .morning, referenceDate: date(hour: 7), calendar: calendar)
        XCTAssertEqual(timing.progress, 0.0, accuracy: 0.001)
    }

    func testProgressAtMidpointOfMorningIsHalf() {
        // Morning spans 7–12 (5 hours). 9:30 is the midpoint.
        let timing = RhythmTiming(now: .morning, referenceDate: date(hour: 9, minute: 30), calendar: calendar)
        XCTAssertEqual(timing.progress, 0.5, accuracy: 0.001)
    }

    func testProgressForDawnAtSixIsHalf() {
        // Dawn spans 5–7 (2 hours). 6:00 is the midpoint.
        let timing = RhythmTiming(now: .dawn, referenceDate: date(hour: 6), calendar: calendar)
        XCTAssertEqual(timing.progress, 0.5, accuracy: 0.001)
    }

    func testProgressForNightAtStartIsZero() {
        let timing = RhythmTiming(now: .night, referenceDate: date(hour: 21), calendar: calendar)
        XCTAssertEqual(timing.progress, 0.0, accuracy: 0.001)
    }

    func testProgressForNightAtTwentyThreeIsQuarter() {
        // Night spans 21 → 5 (8 hours). At 23:00 we are 2h in → 0.25.
        let timing = RhythmTiming(now: .night, referenceDate: date(hour: 23), calendar: calendar)
        XCTAssertEqual(timing.progress, 0.25, accuracy: 0.001)
    }

    func testProgressForNightHandlesMidnightWrapToOneAM() {
        // Night spans 21 → 5 (8 hours). At 01:00 we are 4h in → 0.5.
        let timing = RhythmTiming(now: .night, referenceDate: date(hour: 1), calendar: calendar)
        XCTAssertEqual(timing.progress, 0.5, accuracy: 0.001)
    }

    // MARK: - RhythmTiming.nextBlockStart

    func testNextBlockStartSameDayWhenLater() {
        // Evening at 19:00 → night starts at 21:00 same day.
        let now = date(hour: 19)
        let timing = RhythmTiming(now: .evening, referenceDate: now, calendar: calendar)
        XCTAssertEqual(timing.nextBlockStart, date(hour: 21))
    }

    func testNextBlockStartWrapsToTomorrowWhenEarlier() {
        // Night at 23:00 → dawn at 5:00 the next day.
        let now = date(hour: 23)
        let timing = RhythmTiming(now: .night, referenceDate: now, calendar: calendar)
        XCTAssertEqual(timing.nextBlockStart, date(day: 4, hour: 5))
    }

    func testNextBlockStartForNightAfterMidnightStaysToday() {
        // Night at 03:00 (already past midnight, still night) → dawn at 5:00 same calendar day.
        let now = date(hour: 3)
        let timing = RhythmTiming(now: .night, referenceDate: now, calendar: calendar)
        XCTAssertEqual(timing.nextBlockStart, date(hour: 5))
    }
}
