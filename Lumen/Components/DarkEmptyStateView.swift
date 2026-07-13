import SwiftUI

struct DarkEmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    let guidance: [String]
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        icon: String,
        title: String,
        message: String,
        guidance: [String] = [],
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.guidance = guidance
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 58, height: 58)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color(hex: "#C49A6C"))
            }

            VStack(spacing: 7) {
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.48))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !guidance.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(guidance.enumerated()), id: \.offset) { index, item in
                        guidanceRow(index: index, text: item)
                    }
                }
                .padding(.top, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(Color(hex: "#C49A6C"), in: RoundedRectangle(cornerRadius: 16))
                }
                .padding(.top, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: 420)
        .background(Color.white.opacity(0.055), in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .frame(maxWidth: .infinity)
    }

    private func guidanceRow(index: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(index + 1)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "#C49A6C"))
                .frame(width: 22, height: 22)
                .background(Color(hex: "#C49A6C").opacity(0.13), in: Circle())

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.opacity(0.48))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
