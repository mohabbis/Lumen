import SwiftUI

struct EmptyStateView: View {

    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(Color("TertiaryText"))

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
                    .multilineTextAlignment(.center)
            }

            if let action, let actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.body.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color("MuhaBrown"), in: Capsule())
                        .foregroundStyle(Color("MuhaCream"))
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}