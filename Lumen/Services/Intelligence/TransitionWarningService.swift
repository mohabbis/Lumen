import Foundation
import UserNotifications

// MARK: - Transition Warning Service
// Schedules local notifications before rhythm transitions
// (e.g. "Evening starts in 15 minutes"). Lead time comes from
// SensoryProfile.transitionWarningMinutes (0 = off).

@MainActor
final class TransitionWarningService {

    static let shared = TransitionWarningService()
    private init() {}

    private var scheduledNotificationIDs: [String] = []

    /// Schedule notifications for upcoming rhythm transitions today.
    func scheduleWarnings(
        profile: SensoryProfile,
        from referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) {
        let leadMinutes = profile.transitionWarningMinutes
        guard leadMinutes > 0 else {
            cancelAll()
            return
        }

        cancelAll()

        let schedule = TransitionSchedule(
            leadMinutes: leadMinutes,
            referenceDate: referenceDate,
            calendar: calendar
        )

        for warning in schedule.upcomingWarnings {
            scheduleNotification(warning: warning)
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: scheduledNotificationIDs)
        scheduledNotificationIDs.removeAll()
    }

    private func scheduleNotification(warning: TransitionWarning) {
        let content = UNMutableNotificationContent()
        content.title = "Rhythm Change"
        content.body = warning.message
        content.sound = .default
        content.categoryIdentifier = "lumen.transition"
        content.interruptionLevel = .passive

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, warning.fireDate.timeIntervalSinceNow),
            repeats: false
        )

        let id = "lumen.transition.\(warning.block.name).\(warning.id)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[TransitionWarningService] Failed to schedule: \(error.localizedDescription)")
            }
        }

        scheduledNotificationIDs.append(id)
    }
}

// MARK: - TransitionSchedule (pure)

struct TransitionSchedule: Equatable {

    let leadMinutes: Int
    let referenceDate: Date
    let calendar: Calendar

    private static let allBlocks: [TimeOfDay] = [.dawn, .morning, .afternoon, .evening, .night]

    var upcomingWarnings: [TransitionWarning] {
        guard leadMinutes > 0 else { return [] }

        var warnings: [TransitionWarning] = []
        let leadSeconds = TimeInterval(leadMinutes * 60)

        for block in Self.allBlocks {
            let transitionDate = nextTransitionDate(for: block)
            let warningDate = transitionDate.addingTimeInterval(-leadSeconds)
            guard warningDate > referenceDate else { continue }

            warnings.append(
                TransitionWarning(
                    block: block,
                    transitionDate: transitionDate,
                    fireDate: warningDate,
                    leadMinutes: leadMinutes
                )
            )
        }

        return warnings.sorted { $0.fireDate < $1.fireDate }
    }

    var warningCount: Int { upcomingWarnings.count }

    private func nextTransitionDate(for block: TimeOfDay) -> Date {
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = block.startHour
        components.minute = 0
        components.second = 0

        let candidate = calendar.date(from: components) ?? referenceDate
        if candidate > referenceDate {
            return candidate
        }
        return calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate
    }
}

// MARK: - TransitionWarning

struct TransitionWarning: Equatable, Identifiable {
    let id = UUID()
    let block: TimeOfDay
    let transitionDate: Date
    let fireDate: Date
    let leadMinutes: Int

    var message: String {
        "\(block.name) starts in \(leadMinutes) minutes. \(block.rhythmDescription)"
    }

    static func == (lhs: TransitionWarning, rhs: TransitionWarning) -> Bool {
        lhs.block == rhs.block &&
        lhs.transitionDate == rhs.transitionDate &&
        lhs.fireDate == rhs.fireDate &&
        lhs.leadMinutes == rhs.leadMinutes
    }
}
