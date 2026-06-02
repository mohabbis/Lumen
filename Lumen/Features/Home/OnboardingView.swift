import SwiftUI

// MARK: - Onboarding View

struct OnboardingView: View {

    let onCreate: (String) -> Void

    @State private var homeName = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        ZStack {
            Color(hex: "#0E0819").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 80, height: 80)
                        Image(systemName: "house.fill")
                            .font(.system(size: 34))
                            .foregroundStyle(Color(hex: "#C49A6C"))
                    }

                    VStack(spacing: 8) {
                        Text("Welcome to Lumen")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Name your home to get started.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.45))
                            .multilineTextAlignment(.center)
                    }
                }

                Spacer()

                VStack(spacing: 14) {
                    TextField("Home Name", text: $homeName)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                        .autocorrectionDisabled()
                        .focused($nameFieldFocused)
                        .onSubmit { submitIfValid() }

                    Button(action: submitIfValid) {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "#C49A6C"), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(homeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
            }
        }
        .onAppear { nameFieldFocused = true }
    }

    private func submitIfValid() {
        let cleaned = homeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        onCreate(cleaned)
    }
}
