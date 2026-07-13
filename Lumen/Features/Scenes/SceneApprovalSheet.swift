import SwiftUI

// MARK: - Scene Approval Sheet
// Consent-before-action surface: shows what a scene will do, asks the user
// to confirm before the scene fires. Tone matches the calm-pivot direction —
// nothing runs silently.

struct SceneApprovalSheet: View {

    let scene: Scene
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            handle
            ScrollView {
                VStack(spacing: 0) {
                    header
                    actionList
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            confirmButton
            cancelButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(Color(hex: "#0E0819").ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Subviews

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.18))
            .frame(width: 36, height: 4)
            .padding(.bottom, 20)
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 64, height: 64)
                Image(systemName: scene.iconName)
                    .font(.system(size: 26))
                    .foregroundStyle(Color(hex: "#C49A6C"))
            }

            VStack(spacing: 6) {
                Text("APPLY SCENE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text(scene.name)
                    .font(.system(size: 26, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 24)
    }

    private var actionList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LUMEN WILL")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.35))

            if scene.actions.isEmpty {
                SceneActionSummaryRow(capability: "Apply preset", detail: "Across your reachable devices")
            } else {
                ForEach(sortedActions, id: \.id) { action in
                    let description = SceneActionDescription(action: action)
                    SceneActionSummaryRow(capability: description.capability, detail: description.detail)
                }
            }
        }
    }

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text("Apply")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(hex: "#C49A6C"), in: RoundedRectangle(cornerRadius: 18))
        }
        .padding(.bottom, 10)
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("Cancel")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }

    private var sortedActions: [SceneAction] {
        scene.actions.sorted { $0.sortOrder < $1.sortOrder }
    }
}

// MARK: - SceneActionSummaryRow

struct SceneActionSummaryRow: View {

    let capability: String
    let detail: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                capabilityText
                    .lineLimit(1)
                    .layoutPriority(1)
                Spacer(minLength: 8)
                detailText
                    .lineLimit(1)
                    .multilineTextAlignment(.trailing)
            }

            VStack(alignment: .leading, spacing: 4) {
                capabilityText
                    .fixedSize(horizontal: false, vertical: true)
                detailText
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private var capabilityText: some View {
        Text(capability)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.85))
    }

    private var detailText: some View {
        Text(detail)
            .font(.system(size: 14))
            .foregroundStyle(Color.white.opacity(0.55))
    }
}

// MARK: - SceneActionDescription
// Pure formatter for a SceneAction → (capability, detail) pair shown in the
// approval sheet. Lifted into a struct so it can be unit-tested without UI.

struct SceneActionDescription: Equatable {

    let capability: String
    let detail: String

    init(action: SceneAction) {
        self.capability = Self.capabilityName(for: action.capabilityRaw)
        self.detail = Self.detail(for: action)
    }

    init(capability: String, detail: String) {
        self.capability = capability
        self.detail = detail
    }

    private static func capabilityName(for raw: String) -> String {
        switch raw {
        case "onOff", "power": return "Power"
        case "brightness":  return "Brightness"
        case "color", "colorHue": return "Color"
        case "colorTemperature": return "Color Temperature"
        case "temperature", "targetTemperature": return "Temperature"
        case "hvacMode":    return "Mode"
        case "lock", "lockState": return "Lock"
        case "position":    return "Position"
        default:
            guard let first = raw.first else { return raw }
            return first.uppercased() + raw.dropFirst()
        }
    }

    private static func detail(for action: SceneAction) -> String {
        switch action.payloadTypeRaw {
        case "bool":
            return action.payloadBool == true ? "On" : "Off"
        case "double":
            guard let value = action.payloadDouble else { return "—" }
            // brightness is 0–1; render as percentage
            if action.capabilityRaw == "brightness" {
                return "\(Int((value * 100).rounded()))%"
            }
            return String(format: "%.1f", value)
        case "int":
            return action.payloadInt.map { "\($0)" } ?? "—"
        case "colorHSB":
            return "Custom color"
        case "temperature":
            guard let value = action.payloadDouble else { return "—" }
            return "\(Int(value.rounded()))°C"
        case "hvacMode":
            return "Mode"
        case "lockState", "lock":
            return action.payloadInt == 0 ? "Locked" : "Unlocked"
        default:
            return "Set"
        }
    }
}
