import Foundation

// MARK: - Schedule Timing
// Pure, calendar-injectable logic for daily scene schedules. Lifted out of
// SceneService so the "is this scene due to fire now?" decision can be
// unit-tested without SwiftData, timers, or notifications — the same convention
// as RhythmTiming / SuggestionEngine.

enum ScheduleTiming {

    /// The moment a `minutesSinceMidnight` schedule fires on the day containing
    /// `reference` (local time). Returns nil for an out-of-range value.
    static func fireDate(
        minutesSinceMidnight: Int,
        on reference: Date,
        calendar: Calendar = .current
    ) -> Date? {
        guard (0..<1440).contains(minutesSinceMidnight) else { return nil }
        let start = calendar.startOfDay(for: reference)
        return calendar.date(byAdding: .minute, value: minutesSinceMidnight, to: start)
    }

    /// Whether a schedule is due to fire at `now`:
    /// - `now` is at or after today's fire moment, and within `grace` of it
    ///   (so a scene missed by hours — e.g. the app was closed — does **not**
    ///   fire stale on next launch), and
    /// - it has not already fired at or after today's fire moment.
    ///
    /// The grace window keeps firing calm and predictable: a scheduled scene runs
    /// close to its time or not at all, never surprising the user long after.
    static func isDue(
        minutesSinceMidnight: Int,
        now: Date,
        lastFired: Date?,
        grace: TimeInterval = 120,
        calendar: Calendar = .current
    ) -> Bool {
        guard let fire = fireDate(minutesSinceMidnight: minutesSinceMidnight, on: now, calendar: calendar) else {
            return false
        }
        guard now >= fire, now <= fire.addingTimeInterval(grace) else { return false }
        if let lastFired, lastFired >= fire { return false }
        return true
    }
}
