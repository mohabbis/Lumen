import SwiftUI

// MARK: - Visual Timeline View
// Full-day horizontal timeline showing all 5 rhythm blocks with the current
// time indicator, scheduled scenes, and execution history. Tiimo-inspired
// color-coded blocks give neurodivergent users a visual anchor for their day.

struct VisualTimelineView: View {

    let now: TimeOfDay
    let referenceDate: Date
    var executionHistory: [TimelineEvent] = []
    var calendar: Calendar = .current

    private let blocks: [TimeOfDay] = [.dawn, .morning, .afternoon, .evening, .night]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("YOUR DAY")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    ZStack(alignment: .topLeading) {
                        timelineBlocks
                        currentTimeIndicator
                        eventDots
                    }
                    .frame(height: 110)
                    .padding(.horizontal, 4)
                }
                .onAppear {
                    proxy.scrollTo(now.name, anchor: .center)
                }
            }

            legendRow
        }
        .padding(18)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
        )
    }

    // MARK: - Timeline Blocks

    private var timelineBlocks: some View {
        HStack(spacing: 3) {
            ForEach(blocks, id: \.name) { block in
                TimelineBlock(
                    block: block,
                    isCurrent: block == now,
                    progress: block == now ? blockProgress : nil
                )
                .id(block.name)
            }
        }
    }

    // MARK: - Current Time Indicator

    private var currentTimeIndicator: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let fraction = dayFraction
            let xPos = totalWidth * fraction

            VStack(spacing: 2) {
                Text(currentTimeFormatted)
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundStyle(now.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(now.accentColor.opacity(0.15), in: Capsule())

                Rectangle()
                    .fill(now.accentColor)
                    .frame(width: 2, height: 70)
            }
            .offset(x: xPos - 20)
        }
    }

    // MARK: - Event Dots

    private var eventDots: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            ForEach(executionHistory) { event in
                let fraction = hourFraction(for: event.hour)
                let xPos = totalWidth * fraction

                Circle()
                    .fill(event.succeeded ? Color(hex: "#6FDBA8") : Color.red.opacity(0.7))
                    .frame(width: 6, height: 6)
                    .offset(x: xPos, y: 90)
            }
        }
    }

    // MARK: - Legend

    private var legendRow: some View {
        HStack(spacing: 16) {
            legendItem(color: now.accentColor, label: "Now")
            legendItem(color: Color(hex: "#6FDBA8"), label: "Executed")
            Spacer()
            Text(dayLabel)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.4))
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.5))
        }
    }

    // MARK: - Computed Properties

    private var blockProgress: Double {
        RhythmTiming(now: now, referenceDate: referenceDate, calendar: calendar).progress
    }

    private var dayFraction: Double {
        let hour = calendar.component(.hour, from: referenceDate)
        let minute = calendar.component(.minute, from: referenceDate)
        return (Double(hour) + Double(minute) / 60.0) / 24.0
    }

    private var currentTimeFormatted: String {
        referenceDate.formatted(date: .omitted, time: .shortened)
    }

    private var dayLabel: String {
        referenceDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func hourFraction(for hour: Int) -> Double {
        Double(hour) / 24.0
    }
}

// MARK: - Timeline Block

private struct TimelineBlock: View {
    let block: TimeOfDay
    let isCurrent: Bool
    var progress: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Block label
            Text(block.name.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(1)
                .foregroundStyle(isCurrent ? .white : Color.white.opacity(0.4))

            // Time range
            Text(timeRange)
                .font(.system(size: 10).monospacedDigit())
                .foregroundStyle(Color.white.opacity(0.3))

            // Block bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(block.accentColor.opacity(isCurrent ? 0.3 : 0.1))
                    .frame(height: 40)

                if let progress {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(block.accentColor.opacity(0.6))
                            .frame(width: max(4, geo.size.width * progress), height: 40)
                    }
                    .frame(height: 40)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(
                        isCurrent ? block.accentColor.opacity(0.4) : Color.clear,
                        lineWidth: 1
                    )
            )

            // Block description
            if isCurrent {
                Text(block.rhythmDescription)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .frame(width: blockWidth)
    }

    private var blockWidth: CGFloat {
        let hours = Double(block.durationHours)
        // Scale: roughly 20pt per hour, minimum 60pt
        return max(60, hours * 20)
    }

    private var timeRange: String {
        let start = formatHour(block.startHour)
        let end = formatHour(block.endHour)
        return "\(start)–\(end)"
    }

    private func formatHour(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "a" : "p"
        return "\(h)\(suffix)"
    }
}

// MARK: - Timeline Event

struct TimelineEvent: Identifiable, Equatable {
    let id: UUID
    let hour: Int
    let sceneName: String
    let succeeded: Bool

    init(id: UUID = UUID(), hour: Int, sceneName: String, succeeded: Bool = true) {
        self.id = id
        self.hour = hour
        self.sceneName = sceneName
        self.succeeded = succeeded
    }
}

// MARK: - TimeOfDay Duration Extension

extension TimeOfDay {
    var durationHours: Int {
        let start = startHour
        let end = endHour
        if end > start {
            return end - start
        }
        return (24 - start) + end // Night wraps midnight
    }
}

#Preview("Timeline - Morning") {
    VStack {
        VisualTimelineView(
            now: .morning,
            referenceDate: {
                var c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                c.hour = 9; c.minute = 30
                return Calendar.current.date(from: c) ?? Date()
            }(),
            executionHistory: [
                TimelineEvent(hour: 7, sceneName: "Morning"),
                TimelineEvent(hour: 8, sceneName: "Lights"),
            ]
        )
    }
    .padding(20)
    .background(Color(hex: "#0E0819"))
}
