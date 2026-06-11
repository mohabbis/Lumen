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
            header
            actionList
            Spacer(minLength: 24)
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
                actionRow(capability: "Apply preset", detail: "Across your reachable devices")
            } else {
                ForEach(sortedActions, id: \.id) { action in
                    let description = SceneActionDescription(action: action)
                    actionRow(capability: description.capability, detail: description.detail)
                }
            }
        }
    }

    private func actionRow(capability: String, detail: String) -> some View {
        HStack {
            Text(capability)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))
            Spacer()
            Text(detail)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
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
        case "power":       return "Power"
        case "brightness":  return "Brightness"
        case "color":       return "Color"
        case "temperature": return "Temperature"
        case "hvacMode":    return "Mode"
        case "lockState":   return "Lock"
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
        case "lockState":
            return action.payloadInt == 0 ? "Locked" : "Unlocked"
        default:
            return "Set"
        }
    }
}
