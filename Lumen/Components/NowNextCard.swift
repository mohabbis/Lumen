import SwiftUI

// MARK: - Now / Next Rhythm Card
// Tiimo-style daily rhythm cue: current time block + next transition.
// Renders without any smart-home devices — gives the app value to users
// who have not connected HomeKit.

struct NowNextCard: View {

    let now: TimeOfDay
    private let timing: RhythmTiming

    init(now: TimeOfDay = .current, referenceDate: Date = Date()) {
        self.now = now
        self.timing = RhythmTiming(now: now, referenceDate: referenceDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RHYTHM")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("NOW")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(now.accentColor)
                    Text(now.name)
                        .font(.system(size: 22, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                }
                Text(now.rhythmDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.55))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                    Capsule()
                        .fill(now.accentColor.opacity(0.55))
                        .frame(width: max(4, geo.size.width * timing.progress))
                }
            }
            .frame(height: 3)

            HStack(spacing: 8) {
                Text("NEXT")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text(now.nextBlock.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("at \(timing.nextStartFormatted)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
                Spacer()
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }
}

// MARK: - RhythmTiming
// Pure math for the rhythm card — separated from the view so it can be unit-tested
// without spinning up SwiftUI. Calendar is injectable for deterministic tests.

struct RhythmTiming: Equatable {

    let now: TimeOfDay
    let referenceDate: Date
    let calendar: Calendar

    init(now: TimeOfDay, referenceDate: Date, calendar: Calendar = .current) {
        self.now = now
        self.referenceDate = referenceDate
        self.calendar = calendar
    }

    var progress: Double {
        let hour = calendar.component(.hour, from: referenceDate)
        let minute = calendar.component(.minute, from: referenceDate)
        let fractional = Double(hour) + Double(minute) / 60.0

        let start = Double(now.startHour)
        let end = Double(now.endHour)

        // Night wraps midnight (21 → 5).
        if start > end {
            let span = (24 - start) + end
            let into = fractional >= start
                ? (fractional - start)
                : ((24 - start) + fractional)
            return min(1, max(0, into / span))
        }

        return min(1, max(0, (fractional - start) / (end - start)))
    }

    var nextBlockStart: Date {
        var components = calendar.dateComponents([.year, .month, .day], from: referenceDate)
        components.hour = now.nextBlock.startHour
        components.minute = 0
        let candidate = calendar.date(from: components) ?? referenceDate
        return candidate > referenceDate
            ? candidate
            : (calendar.date(byAdding: .day, value: 1, to: candidate) ?? candidate)
    }

    var nextStartFormatted: String {
        nextBlockStart.formatted(date: .omitted, time: .shortened)
    }
}

extension TimeOfDay {
    var name: String {
        switch self {
        case .dawn:      return "Dawn"
        case .morning:   return "Morning"
        case .afternoon: return "Afternoon"
        case .evening:   return "Evening"
        case .night:     return "Night"
        }
    }

    var rhythmDescription: String {
        switch self {
        case .dawn:      return "Your home is waking up."
        case .morning:   return "Settling into the day."
        case .afternoon: return "Steady, bright, alert."
        case .evening:   return "Winding down softly."
        case .night:     return "Quiet and resting."
        }
    }

    var startHour: Int {
        switch self {
        case .dawn:      return 5
        case .morning:   return 7
        case .afternoon: return 12
        case .evening:   return 17
        case .night:     return 21
        }
    }

    var endHour: Int {
        switch self {
        case .dawn:      return 7
        case .morning:   return 12
        case .afternoon: return 17
        case .evening:   return 21
        case .night:     return 5
        }
    }

    var nextBlock: TimeOfDay {
        switch self {
        case .dawn:      return .morning
        case .morning:   return .afternoon
        case .afternoon: return .evening
        case .evening:   return .night
        case .night:     return .dawn
        }
    }
}

#Preview("All time blocks") {
    ScrollView {
        VStack(spacing: 12) {
            NowNextCard(now: .dawn,      referenceDate: makeDate(hour: 6,  minute: 0))
            NowNextCard(now: .morning,   referenceDate: makeDate(hour: 9,  minute: 30))
            NowNextCard(now: .afternoon, referenceDate: makeDate(hour: 14, minute: 15))
            NowNextCard(now: .evening,   referenceDate: makeDate(hour: 19, minute: 0))
            NowNextCard(now: .night,     referenceDate: makeDate(hour: 23, minute: 45))
        }
        .padding(20)
    }
    .background(Color(hex: "#0E0819"))
}

private func makeDate(hour: Int, minute: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
    components.hour = hour
    components.minute = minute
    return Calendar.current.date(from: components) ?? Date()
}
