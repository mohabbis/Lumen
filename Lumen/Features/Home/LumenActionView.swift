import SwiftUI

// MARK: - Lumen Action View
// Consent-before-action surface for Lumen-suggested scenes: shows what actions
// will be taken, asks the user to confirm before the scene fires. Completes
// the 4-mode flow: Awareness → Reasoning → Action → Execution.

struct LumenActionView: View {

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
                Text("APPLY SUGGESTED SCENE")
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
        .buttonStyle(.pressable)
        .padding(.bottom, 10)
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text("Not now")
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
