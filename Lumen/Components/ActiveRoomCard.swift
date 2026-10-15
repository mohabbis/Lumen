import SwiftUI

// MARK: - Active Room Card
// Enhanced room card that shows activity status — green pulse for
// rooms with active devices, last activity timestamp, and sensor state.
// Replaces RoomCard on the dashboard when device state is available.

struct ActiveRoomCard: View {

    let room: Room
    let activeDeviceCount: Int
    let totalDeviceCount: Int
    var lastActivityDate: Date? = nil
    var hasMotion: Bool = false

    private var isActive: Bool { activeDeviceCount > 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: room.type.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(isActive ? Color(hex: "#C49A6C") : Color.white.opacity(0.4))

                Spacer()

                if isActive {
                    activePulse
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(room.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                statusText
            }

            if hasMotion {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: "#6FDBA8"))
                        .frame(width: 5, height: 5)
                    Text("Motion")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color(hex: "#6FDBA8"))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .aspectRatio(1, contentMode: .fit)
        .background(
            isActive
                ? Color(hex: "#C49A6C").opacity(0.06)
                : Color.white.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isActive ? Color(hex: "#C49A6C").opacity(0.15) : Color.white.opacity(0.06),
                    lineWidth: 1
                )
        )
    }

    private var activePulse: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "#6FDBA8"))
                .frame(width: 6, height: 6)
            Circle()
                .stroke(Color(hex: "#6FDBA8").opacity(0.3), lineWidth: 1)
                .frame(width: 12, height: 12)
        }
    }

    @ViewBuilder
    private var statusText: some View {
        if isActive {
            Text("\(activeDeviceCount) active")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#C49A6C").opacity(0.7))
        } else if let lastDate = lastActivityDate {
            Text("Last: \(timeAgo(lastDate))")
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.3))
        } else {
            Text("\(totalDeviceCount) device\(totalDeviceCount == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.35))
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes)m ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h ago" }
        return "\(hours / 24)d ago"
    }
}
