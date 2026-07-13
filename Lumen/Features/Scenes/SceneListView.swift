import SwiftUI
import SwiftData

// MARK: - Scene List View

struct SceneListView: View {

    @State var viewModel: SceneViewModel
    @Query(sort: \Scene.sortOrder) private var scenes: [Scene]
    @State private var newSceneName = ""
    @Environment(\.horizontalSizeClass) private var sizeClass
    @FocusState private var isSceneNameFocused: Bool

    private var isIPad: Bool { sizeClass == .regular }
    private var trimmedSceneName: String {
        newSceneName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ZStack {
            Color(hex: "#0E0819").ignoresSafeArea()

            if scenes.isEmpty {
                emptyState
            } else {
                scrollContent
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.isShowingAddScene) {
            addSceneSheet
        }
        .sheet(item: $viewModel.pendingScene) { scene in
            SceneApprovalSheet(
                scene: scene,
                onConfirm: { viewModel.confirmPending() },
                onCancel: { viewModel.cancelPending() }
            )
        }
        .sheet(item: $viewModel.editingScene) { scene in
            NavigationStack {
                SceneDetailView(scene: scene, viewModel: viewModel)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { viewModel.editingScene = nil }
                        }
                    }
            }
        }
        .alert("Something went wrong", isPresented: errorBinding) {
            Button("OK", role: .cancel) { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Please try again.")
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }

    // MARK: - Scroll Content

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if let active = viewModel.lastExecuted {
                    ActiveSceneCard(
                        scene: active,
                        isExecuting: viewModel.executingSceneID == active.id
                    )
                    .onTapGesture { viewModel.requestApproval(active) }
                }

                allScenesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 48)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("LUMEN")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(3.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Text("Scenes")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Button { viewModel.isShowingAddScene = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .padding(.top, 4)
        }
    }

    // MARK: - All Scenes Section

    private var allScenesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ALL SCENES")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            if isIPad {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(scenes, id: \.id) { scene in
                        SceneDarkRow(scene: scene, viewModel: viewModel)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(scenes, id: \.id) { scene in
                        SceneDarkRow(scene: scene, viewModel: viewModel)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.horizontal, 20)
                .padding(.top, 16)
            Spacer()
            DarkEmptyStateView(
                icon: "sparkles",
                title: "Create a calm scene",
                message: "Scenes collect a few device changes into one reviewable action. Lumen will still ask before running them.",
                guidance: [
                    "Name the intent, like Evening or Away.",
                    "Add device actions from the scene detail.",
                    "Every run opens an approval sheet first."
                ],
                actionTitle: "Add Scene",
                action: { viewModel.isShowingAddScene = true }
            )
            .padding(.horizontal, 20)
            Spacer()
        }
    }

    // MARK: - Add Scene Sheet

    private var addSceneSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Scene Name", text: $newSceneName)
                        .textInputAutocapitalization(.words)
                        .focused($isSceneNameFocused)
                        .submitLabel(.done)
                        .onSubmit(addScene)
                } footer: {
                    Text("Use an intent name like Evening or Away. Scene runs still open the approval sheet before anything changes.")
                }
            }
            .navigationTitle("New Scene")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.isShowingAddScene = false
                        newSceneName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: addScene)
                        .disabled(trimmedSceneName.isEmpty)
                }
            }
            .onAppear { isSceneNameFocused = true }
        }
        .presentationDetents([.height(240)])
    }

    private func addScene() {
        guard !trimmedSceneName.isEmpty else { return }
        viewModel.createScene(name: trimmedSceneName)
        newSceneName = ""
    }
}

// MARK: - Active Scene Hero Card

private struct ActiveSceneCard: View {
    let scene: Scene
    let isExecuting: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1E1A3A"), Color(hex: "#0E0819")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    if isExecuting {
                        ProgressView()
                            .scaleEffect(0.6)
                            .tint(Color(hex: "#C49A6C"))
                    } else {
                        Circle()
                            .fill(Color(hex: "#C49A6C"))
                            .frame(width: 6, height: 6)
                    }
                    Text("ACTIVE NOW")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(2)
                        .foregroundStyle(Color(hex: "#C49A6C"))
                }

                Text(scene.name)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .padding(20)
        }
        .frame(height: 165)
    }

    private var subtitle: String {
        let count = scene.actions.count
        let mood = sceneMood(scene.iconName)
        return count > 0 ? "\(count) device\(count == 1 ? "" : "s") · \(mood)" : mood
    }

    private func sceneMood(_ icon: String) -> String {
        switch icon {
        case "sunrise.fill":     return "Bright & energising"
        case "moon.stars.fill":  return "Warm & dim"
        case "popcorn.fill":     return "Dim & ambient"
        case "moon.zzz.fill":    return "All lights off"
        case "house.slash.fill": return "Away mode"
        default:                  return "Custom"
        }
    }
}

// MARK: - Scene Dark Row

private struct SceneDarkRow: View {
    let scene: Scene
    @State var viewModel: SceneViewModel

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 46, height: 46)
                if viewModel.executingSceneID == scene.id {
                    ProgressView().scaleEffect(0.7).tint(.white)
                } else {
                    Image(systemName: scene.iconName)
                        .font(.system(size: 19))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(scene.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                Text(rowSubtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.2))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { viewModel.requestApproval(scene) }
        .contextMenu {
            Button {
                viewModel.requestApproval(scene)
            } label: {
                Label("Run Scene", systemImage: "play.fill")
            }
            Button {
                viewModel.editingScene = scene
            } label: {
                Label("Edit Scene", systemImage: "pencil")
            }
            Button {
                viewModel.toggleFavorite(scene)
            } label: {
                Label(
                    scene.isFavorite ? "Remove Favorite" : "Favorite",
                    systemImage: scene.isFavorite ? "star.slash" : "star"
                )
            }
            Divider()
            Button(role: .destructive) {
                viewModel.deleteScene(scene)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .overlay(alignment: .trailing) {
            Button {
                viewModel.editingScene = scene
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .padding(.trailing, 40)
            }
            .buttonStyle(.plain)
        }
    }

    private var rowSubtitle: String {
        let count = scene.actions.count
        let mood = moodFor(scene.iconName)
        var parts: [String] = []
        if count > 0 {
            parts.append("\(count) device\(count == 1 ? "" : "s")")
        }
        if scene.geofenceTrigger != .none {
            parts.append(scene.geofenceTrigger.displayName)
        }
        if parts.isEmpty { return mood }
        return parts.joined(separator: " · ")
    }

    private func moodFor(_ icon: String) -> String {
        switch icon {
        case "sunrise.fill":     return "Bright & cool"
        case "moon.stars.fill":  return "Warm & dim"
        case "popcorn.fill":     return "Dim & ambient"
        case "moon.zzz.fill":    return "All lights off"
        case "house.slash.fill": return "Away mode"
        default:                  return "Tap to run"
        }
    }
}
