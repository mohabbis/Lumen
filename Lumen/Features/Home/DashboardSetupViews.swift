import SwiftUI

struct FirstRunSetupCard: View {
    let presentation: DashboardSetupPresentation
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.lumenAccent.opacity(0.14))
                        .frame(width: 44, height: 44)
                    Image(systemName: "door.left.hand.open")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.lumenAccent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text("SETUP PATH")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Color.white.opacity(0.35))
                    Text(presentation.title)
                        .font(.system(size: 19, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(presentation.message)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.52))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .layoutPriority(1)
            }

            VStack(spacing: 10) {
                ForEach(presentation.steps) { step in
                    DashboardSetupStepRow(step: step)
                }
            }

            Button(action: action) {
                Text(presentation.actionTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.lumenAccent, in: RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityHint("Opens the room setup sheet.")
        }
        .padding(18)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

private struct DashboardSetupStepRow: View {
    let step: DashboardSetupStep

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(indicatorFill)
                    .frame(width: 22, height: 22)
                Image(systemName: indicatorIcon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(indicatorForeground)
            }
            .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.82))
                Text(step.detail)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.42))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var indicatorFill: Color {
        switch step.state {
        case .complete:
            return Color.lumenSuccess.opacity(0.18)
        case .current:
            return Color.lumenAccent.opacity(0.18)
        case .pending:
            return Color.white.opacity(0.06)
        }
    }

    private var indicatorForeground: Color {
        switch step.state {
        case .complete:
            return Color.lumenSuccess
        case .current:
            return Color.lumenAccent
        case .pending:
            return Color.white.opacity(0.32)
        }
    }

    private var indicatorIcon: String {
        switch step.state {
        case .complete:
            return "checkmark"
        case .current:
            return "arrow.right"
        case .pending:
            return "circle.fill"
        }
    }
}

struct LocationPermissionCard: View {
    let presentation: LocationPermissionPresentation
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 38, height: 38)
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(presentation.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(presentation.message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.48))
                    .fixedSize(horizontal: false, vertical: true)
                Button(action: action) {
                    Text(presentation.actionTitle)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.lumenAccent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.lumenAccent.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }
                .padding(.top, 4)
            }
            .layoutPriority(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}
