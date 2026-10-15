import SwiftUI

// MARK: - Favorite Devices Card
// Quick-access device controls pinned to the dashboard. Users see their
// most important devices with inline power toggles — no navigation needed.
// Reduces cognitive load by keeping the most-used controls at hand.

struct FavoriteDevicesCard: View {

    let devices: [FavoriteDevice]
    var onToggle: ((FavoriteDevice) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QUICK CONTROLS")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            if devices.isEmpty {
                emptyState
            } else {
                VStack(spacing: 2) {
                    ForEach(devices) { device in
                        deviceRow(device)
                    }
                }
                .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )
            }
        }
    }

    private func deviceRow(_ device: FavoriteDevice) -> some View {
        HStack(spacing: 12) {
            // Device icon with status glow
            ZStack {
                Circle()
                    .fill(device.isOn
                          ? device.accentColor.opacity(0.15)
                          : Color.white.opacity(0.06))
                    .frame(width: 36, height: 36)
                Image(systemName: device.iconName)
                    .font(.system(size: 15))
                    .foregroundStyle(device.isOn
                                    ? device.accentColor
                                    : Color.white.opacity(0.4))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                Text(device.roomName)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            // Inline toggle
            Button {
                onToggle?(device)
            } label: {
                Circle()
                    .fill(device.isOn
                          ? device.accentColor.opacity(0.2)
                          : Color.white.opacity(0.08))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "power")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(device.isOn
                                            ? device.accentColor
                                            : Color.white.opacity(0.35))
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(device.isOn
                                         ? device.accentColor.opacity(0.3)
                                         : Color.clear,
                                         lineWidth: 1)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 6) {
                Image(systemName: "star")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.white.opacity(0.2))
                Text("Reachable devices with power control appear here")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.3))
            }
            .padding(.vertical, 24)
            Spacer()
        }
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - FavoriteDevice

/// Lightweight view model for a device pinned to the dashboard.
/// Not persisted in SwiftData — derived from PlannedDevice + live state.
struct FavoriteDevice: Identifiable, Equatable {
    let id: UUID
    let name: String
    let roomName: String
    let iconName: String
    let isOn: Bool
    let category: DeviceCategory

    var accentColor: Color {
        switch category {
        case .lighting:      return Color(hex: "#C49A6C")
        case .climate:       return Color(hex: "#6B9FD4")
        case .security:      return Color(hex: "#6FDBA8")
        case .sensors:       return Color(hex: "#A78BFA")
        case .entertainment: return Color(hex: "#F472B6")
        case .appliances:    return Color.white.opacity(0.6)
        case .other:         return Color.white.opacity(0.5)
        }
    }
}
