import SwiftUI

// MARK: - Calm Mode Dashboard
// One-tap "overwhelm escape" — reduces the full dashboard to absolute
// essentials: a gentle greeting, the rhythm card, and large clear scene
// buttons. No device counts, no stats, no secondary information.
// Designed for moments when the full dashboard is too much.

struct CalmModeDashboard: View {

    let timeOfDay: TimeOfDay
    let homeName: String
    let scenes: [Scene]
    var onSelectScene: ((Scene) -> Void)?
    var onExitCalmMode: (() -> Void)?

    private let calmSceneNames = ["Morning", "Evening", "Sleep", "Away", "Movie Night"]

    var body: some View {
        ZStack {
            ambientBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                Spacer()

                mainContent
                    .padding(.horizontal, 24)

                Spacer()

                sceneButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 44)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("LUMEN")
                .font(.system(size: 10, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.25))
            Spacer()
            Button {
                onExitCalmMode?()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 11))
                    Text("CALM")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                }
                .foregroundStyle(Color.lumenSuccess.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.lumenSuccess.opacity(0.1), in: Capsule())
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 24) {
            // Simple greeting
            VStack(spacing: 8) {
                Text(timeOfDay.greeting)
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(timeOfDay.rhythmDescription)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.white.opacity(0.5))
            }

            // Minimal rhythm indicator
            HStack(spacing: 12) {
                Circle()
                    .fill(timeOfDay.accentColor)
                    .frame(width: 8, height: 8)
                Text(timeOfDay.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.6))
                Text("→")
                    .foregroundStyle(Color.white.opacity(0.3))
                Text(timeOfDay.nextBlock.name)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
        }
    }

    // MARK: - Scene Buttons

    private var sceneButtons: some View {
        VStack(spacing: 12) {
            Text("QUICK SCENES")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2)
                .foregroundStyle(Color.white.opacity(0.25))

            let relevantScenes = scenes.filter { scene in
                calmSceneNames.contains(where: { scene.name.lowercased() == $0.lowercased() })
            }.prefix(3)

            VStack(spacing: 10) {
                ForEach(Array(relevantScenes), id: \.id) { scene in
                    Button {
                        onSelectScene?(scene)
                    } label: {
                        HStack {
                            Image(systemName: scene.iconName)
                                .font(.system(size: 18))
                                .frame(width: 24)
                            Text(scene.name)
                                .font(.system(size: 18, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.3))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Ambient Background

    private var ambientBackground: some View {
        ZStack {
            Color.lumenBackground
            LinearGradient(
                colors: [timeOfDay.backgroundColors.first ?? .clear, .clear],
                startPoint: .top,
                endPoint: .center
            )
            .opacity(0.3)
        }
    }
}
