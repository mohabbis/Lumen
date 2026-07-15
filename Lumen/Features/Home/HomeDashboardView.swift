import SwiftUI
import SwiftData

// MARK: - Home Dashboard View
// Matches the "Awareness" mode shown on lumen.muharafiq.com
// Location-aware: shows "Welcome Home" when at home, "Away Mode" otherwise

struct HomeDashboardView: View {

    @State var viewModel: HomeViewModel
    @Query private var scenes: [Scene]
    @Query private var executions: [ExecutionEvent]
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(LocationService.self) private var locationService
    @Environment(AppState.self) private var appState
    @State private var isRenamingHome = false
    @State private var renameText = ""
    @State private var lumenSheet: LumenDashboardSheet?
    @State private var statusOverlayID = UUID()
    @State private var isStatusOverlayVisible = false

    private var timeOfDay: TimeOfDay { .current }
    private var isRegularLayout: Bool { sizeClass == .regular }
    private var dashboardMaxWidth: CGFloat { isRegularLayout ? 1120 : .infinity }
    private var dashboardHorizontalPadding: CGFloat { isRegularLayout ? 44 : 20 }
    private var dashboardTopPadding: CGFloat { isRegularLayout ? 28 : 8 }
    private var greetingTitleSize: CGFloat { isRegularLayout ? 48 : 36 }
    private var roomLimit: Int { isRegularLayout ? 6 : 4 }
    private var dashboardSetupPresentation: DashboardSetupPresentation {
        DashboardSetupPresentation(
            roomCount: viewModel.rooms.count,
            installedDeviceCount: viewModel.installedDeviceCount,
            sceneCount: scenes.count
        )
    }

    private var locationPermissionPresentation: LocationPermissionPresentation? {
        LocationPermissionPresentation(status: locationService.authorizationStatus)
    }

    private var roomGridColumns: [GridItem] {
        if isRegularLayout {
            [GridItem(.adaptive(minimum: 160, maximum: 220), spacing: 12)]
        } else {
            [GridItem(.flexible()), GridItem(.flexible())]
        }
    }

    var body: some View {
        ZStack {
            if isStatusOverlayVisible {
                StatusOverlay(isAtHome: locationService.isAtHome, id: statusOverlayID)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity),
                                            removal: .move(edge: .top).combined(with: .opacity)))
                    .zIndex(2)
            }
            ambientBackground.ignoresSafeArea()
            if viewModel.hasHome {
                dashboardContent
            } else {
                OnboardingView { name in viewModel.createHome(name: name) }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("Rename Home", isPresented: $isRenamingHome) {
            TextField("Home name", text: $renameText)
            Button("Save") { viewModel.renameHome(to: renameText) }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Something went wrong", isPresented: errorAlertBinding) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(viewModel.error?.localizedDescription ?? "Please try again.")
        }
        .sheet(isPresented: $viewModel.isShowingAddRoom) {
            AddRoomView { name, type, level in
                viewModel.addRoom(name: name, type: type, level: level)
            }
        }
        .sheet(item: $lumenSheet) { sheet in
            lumenSheetContent(sheet)
        }
        .animation(appState.sensoryProfile.shouldReduceMotion ? .default : .spring(response: 0.42, dampingFraction: 0.86), value: isStatusOverlayVisible)
        .onAppear {
            viewModel.load()
            locationService.requestLocationPermission()
            locationService.startMonitoringLocation()
            if let home = viewModel.home, let lat = home.latitude, let lon = home.longitude {
                locationService.updateHomeCoordinates(latitude: lat, longitude: lon)
            }
            showStatusOverlay()
        }
        .onChange(of: locationService.isAtHome) { _, _ in
            LumenHaptics.impact(.soft)
            showStatusOverlay()
        }
        .onDisappear {
            locationService.stopMonitoringLocation()
        }
    }

    // MARK: - Ambient Background (time-of-day gradient)

    private var ambientBackground: some View {
        ZStack {
            if locationService.isAtHome {
                Color.lumenBackground
                LinearGradient(
                    colors: [timeOfDay.backgroundColors.first ?? .clear, .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .opacity(0.6)
            } else {
                // Away mode: darker, more muted background
                Color(hex: "#0A0610")
                LinearGradient(
                    colors: [Color(hex: "#1A0F24"), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
                .opacity(0.4)
            }
        }
    }

    // MARK: - Main Content

    private var dashboardContent: some View {
        ScrollView {
            Group {
                if isRegularLayout {
                    desktopDashboardContent
                } else {
                    phoneDashboardContent
                }
            }
            .frame(maxWidth: dashboardMaxWidth, alignment: .topLeading)
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, dashboardHorizontalPadding)
            .padding(.top, dashboardTopPadding)
            .padding(.bottom, 56)
        }
        .scrollIndicators(.hidden)
    }

    private var phoneDashboardContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            topBar
            greeting
            if let locationPermissionPresentation {
                LocationPermissionCard(
                    presentation: locationPermissionPresentation,
                    action: openAppSettings
                )
            }
            compactStats
            NowNextCard(now: timeOfDay)
            if dashboardSetupPresentation.shouldShow {
                dashboardSetupSection
            } else {
                favoriteRoomsSection
            }
            lumenNoticedSection
        }
    }

    private var desktopDashboardContent: some View {
        VStack(alignment: .leading, spacing: 32) {
            topBar

            HStack(alignment: .top, spacing: 28) {
                VStack(alignment: .leading, spacing: 28) {
                    greeting
                    if let locationPermissionPresentation {
                        LocationPermissionCard(
                            presentation: locationPermissionPresentation,
                            action: openAppSettings
                        )
                    }
                    compactStats
                    NowNextCard(now: timeOfDay)
                    if dashboardSetupPresentation.shouldShow {
                        dashboardSetupSection
                    } else {
                        favoriteRoomsSection
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)

                VStack(alignment: .leading, spacing: 16) {
                    lumenNoticedSection
                }
                .frame(width: 340, alignment: .topLeading)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("LUMEN")
                .font(.system(size: 10, weight: .semibold))
                .tracking(4)
                .foregroundStyle(Color.white.opacity(0.35))
            Spacer()
            HStack(spacing: 6) {
                Text(locationService.isAtHome ? "HOME MODE" : "AWAY MODE")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2)
                    .foregroundStyle(locationService.isAtHome ? Color.lumenAccent : Color.white.opacity(0.35))
                Image(systemName: locationService.isAtHome ? "house.fill" : "location.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(locationService.isAtHome ? Color.lumenAccent : Color.white.opacity(0.35))
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Greeting

    private var greeting: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                if locationService.isAtHome {
                    Text("Welcome Home,")
                        .font(.system(size: greetingTitleSize, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                } else {
                    Text(timeOfDay.greeting + ",")
                        .font(.system(size: greetingTitleSize, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                Text(viewModel.home?.name ?? "Home")
                    .font(.system(size: greetingTitleSize, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .onLongPressGesture {
                        renameText = viewModel.home?.name ?? ""
                        isRenamingHome = true
                    }
            }

            Text(homeStatusSubtitle)
                .font(.system(size: isRegularLayout ? 15 : 14))
                .foregroundStyle(Color.white.opacity(0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var homeStatusSubtitle: String {
        if !locationService.isAtHome {
            if let distance = locationService.distanceToHome {
                let km = distance / 1000
                return String(format: "Away Mode — %.1f km from home", km)
            }
            return "Away Mode"
        }
        
        let rooms = viewModel.rooms.count
        let online = viewModel.reachableDeviceCount
        let total = viewModel.installedDeviceCount
        if rooms == 0 { return "Add rooms to get started." }
        if online == 0 { return "Your home is quiet." }
        return "\(online) of \(total) device\(total == 1 ? "" : "s") online — all looking good."
    }

    // MARK: - Compact Stats

    private var compactStats: some View {
        HStack(spacing: 0) {
            statChip(value: "\(viewModel.rooms.count)", label: "rooms")
            Text(" · ").foregroundStyle(Color.white.opacity(0.2)).font(.system(size: 13))
            statChip(value: "\(viewModel.installedDeviceCount)", label: "devices")
            Text(" · ").foregroundStyle(Color.white.opacity(0.2)).font(.system(size: 13))
            statChip(value: "\(scenes.count)", label: "automations")
            Spacer()
            Button { viewModel.isShowingAddRoom = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .disabled(!viewModel.hasHome)
        }
    }

    private func statChip(value: String, label: String) -> some View {
        HStack(spacing: 3) {
            Text(value)
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.45))
        }
    }

    // MARK: - Favorite Rooms Section

    private var favoriteRoomsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("FAVORITE ROOMS")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Spacer()
                NavigationLink(destination: RoomListView(viewModel: viewModel.makeRoomViewModel())) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
            }

            LazyVGrid(columns: roomGridColumns, spacing: isRegularLayout ? 12 : 10) {
                ForEach(viewModel.rooms.prefix(roomLimit), id: \.id) { room in
                    NavigationLink(destination: RoomDetailView(
                        room: room,
                        viewModel: viewModel.makeRoomViewModel()
                    )) {
                        RoomCard(room: room)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - First-Run Setup

    private var dashboardSetupSection: some View {
        FirstRunSetupCard(
            presentation: dashboardSetupPresentation,
            action: { viewModel.isShowingAddRoom = true }
        )
    }

    // MARK: - Lumen Noticed Section

    private var lumenNoticedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LUMEN NOTICED")
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(2.5)
                    .foregroundStyle(Color.white.opacity(0.35))
                Spacer()
                if appState.suggestionsPaused {
                    Button(action: { appState.suggestionsPaused = false }) {
                        Label("Resume", systemImage: "play.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.lumenAccent)
                    }
                } else if suggestion != nil {
                    Button(action: { appState.suggestionsPaused = true }) {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                }
            }

            VStack(spacing: 8) {
                if appState.suggestionsPaused {
                    LumenNoticedCard(
                        message: "Suggestions are paused.",
                        suggestion: "Tap resume to receive suggestions again.",
                        detail: "You can unpause anytime.",
                        icon: "pause.fill",
                        isActionable: true,
                        action: { appState.suggestionsPaused = false }
                    )
                } else if let suggestion = suggestion {
                    LumenNoticedCard(
                        message: noticePresentation.message,
                        suggestion: noticePresentation.suggestion,
                        detail: noticePresentation.detail,
                        icon: noticePresentation.iconName,
                        isActionable: noticePresentation.isActionable,
                        action: { lumenSheet = .reasoning }
                    )
                } else {
                    LumenNoticedCard(
                        message: "Lumen is monitoring your home.",
                        suggestion: "No suggestions right now.",
                        detail: "Everything looks calm.",
                        icon: "sparkles",
                        isActionable: false,
                        action: {}
                    )
                }
            }
        }
    }

    // MARK: - Lumen Suggestion Handler

    @ViewBuilder
    private func lumenSheetContent(_ sheet: LumenDashboardSheet) -> some View {
        switch sheet {
        case .reasoning:
            LumenReasoningView(
                reasoning: reasoning,
                onApply: reasoningApplyAction,
                onDismiss: { lumenSheet = nil }
            )
        case .action:
            lumenActionSheet
        }
    }

    @ViewBuilder
    private var lumenActionSheet: some View {
        if let sceneName = suggestedSceneName, let scene = findScene(named: sceneName) {
            LumenActionView(
                scene: scene,
                onConfirm: { handleLumenSuggestion() },
                onCancel: { lumenSheet = nil }
            )
        } else {
            // Fallback if the suggested scene becomes unavailable mid-flow.
            VStack(spacing: 12) {
                Text("Scene not available")
                    .font(.title2)
                    .foregroundStyle(.white)
                Button("Done") {
                    lumenSheet = nil
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.lumenAccent, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(24)
            .background(Color.lumenBackground.ignoresSafeArea())
        }
    }

    private var reasoningApplyAction: (() -> Void)? {
        if noticePresentation.isActionable {
            return showLumenActionIfAvailable
        }
        return nil
    }

    private func showLumenActionIfAvailable() {
        guard noticePresentation.isActionable else { return }
        lumenSheet = .action
    }

    private func handleLumenSuggestion() {
        lumenSheet = nil
        
        // Record that a suggestion was shown today (for sensory profile limits)
        appState.recordSuggestionShown()

        // Execute the same scene the Action sheet displayed — single source of truth.
        if let sceneName = suggestedSceneName, let scene = findScene(named: sceneName) {
            Task { await viewModel.executeScene(scene) }
        }
    }

    private func showStatusOverlay() {
        let id = UUID()
        statusOverlayID = id

        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            isStatusOverlayVisible = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            guard statusOverlayID == id else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                isStatusOverlayVisible = false
            }
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private func findScene(named name: String) -> Scene? {
        scenes.first { $0.name.lowercased() == name.lowercased() }
    }

    // MARK: - Scored suggestion (SuggestionEngine)

    // Value-type view of every scene + its run history, fed to the pure engine.
    private var suggestionCandidates: [SuggestionCandidate] {
        scenes.map { scene in
            var runsByHour: [Int: Int] = [:]
            for event in executions where event.sceneName.lowercased() == scene.name.lowercased() {
                runsByHour[event.hourOfDay, default: 0] += 1
            }
            return SuggestionCandidate(
                sceneName: scene.name,
                geofenceTrigger: scene.geofenceTrigger,
                isFavorite: scene.isFavorite,
                runsByHour: runsByHour
            )
        }
    }

    private var suggestion: SceneSuggestion? {
        SuggestionEngine(
            timeOfDay: timeOfDay,
            presence: locationService.isAtHome ? .home : .away,
            reachableDevices: viewModel.reachableDeviceCount,
            hourOfDay: Calendar.current.component(.hour, from: Date()),
            candidates: suggestionCandidates,
            dailySuggestionLimit: appState.sensoryProfile.dailySuggestionLimit,
            pausedSuggestions: appState.suggestionsPaused,
            hasShownSuggestionToday: appState.hasReachedDailySuggestionLimit
        ).topSuggestion()
    }

    private var expectedSceneName: String? {
        if let name = suggestion?.sceneName {
            return name
        }

        guard let name = defaultExpectedSceneName, findScene(named: name) == nil else {
            return nil
        }

        return name
    }

    private var defaultExpectedSceneName: String? {
        switch timeOfDay {
        case .dawn, .morning: return "Morning"
        case .afternoon:      return nil
        case .evening:        return "Evening"
        case .night:          return "Sleep"
        }
    }

    private var suggestedSceneName: String? {
        guard let name = suggestion?.sceneName, let scene = findScene(named: name) else { return nil }
        return scene.name
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )
    }

    private var reasoning: LumenReasoning {
        ReasoningCalculator(
            timeOfDay: timeOfDay,
            isAtHome: locationService.isAtHome,
            distanceToHome: locationService.distanceToHome,
            reachableDevices: viewModel.reachableDeviceCount,
            suggestedSceneName: suggestedSceneName,
            expectedSceneName: expectedSceneName,
            confidence: suggestion?.confidence,
            habitRuns: suggestion?.habitRuns,
            factors: suggestion?.factors ?? []
        ).reasoning
    }

    private var noticePresentation: LumenNoticePresentation {
        LumenNoticePresentation(
            timeOfDay: timeOfDay,
            isAtHome: locationService.isAtHome,
            reachableDevices: viewModel.reachableDeviceCount,
            expectedSceneName: expectedSceneName,
            suggestedSceneName: suggestedSceneName
        )
    }
}

private enum LumenDashboardSheet: String, Identifiable {
    case reasoning
    case action

    var id: String { rawValue }
}

private struct StatusOverlay: View {
    let isAtHome: Bool
    let id: UUID
    @State private var animate = false

    var body: some View {
        VStack {
            banner
                .scaleEffect(animate ? 1 : 0.96)
                .opacity(animate ? 1 : 0)
                .padding(.horizontal, 20)
                .padding(.top, 14)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .id(id)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                animate = true
            }
        }
    }

    private var banner: some View {
        let presentation = StatusOverlayPresentation(isAtHome: isAtHome)

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: presentation.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(presentation.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text(presentation.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.52))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .layoutPriority(1)
        }
        .frame(maxWidth: 360, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: "#140D1F").opacity(0.96), in: RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        let presentation = StatusOverlayPresentation(isAtHome: isAtHome)
        return Color(hex: presentation.tintHex).opacity(presentation.tintOpacity)
    }
}

private struct LumenNoticedCard: View {
    let message: String
    let suggestion: String
    let detail: String
    let icon: String
    let isActionable: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lumenAccent)
                    Text("Lumen noticed")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color.lumenAccent)
                }

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                cardFooter
            }
            .padding(18)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
        .accessibilityHint(isActionable ? "Opens reasoning before confirmation." : "Opens the current signal details.")
    }

    private var cardFooter: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 12) {
                footerText
                    .layoutPriority(1)
                Spacer(minLength: 8)
                footerIcon
            }

            VStack(alignment: .leading, spacing: 8) {
                footerText
                footerIcon
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private var footerText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(suggestion)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.28))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var footerIcon: some View {
        Image(systemName: isActionable ? "chevron.right" : "info.circle")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(isActionable ? Color.lumenAccent : Color.white.opacity(0.35))
            .frame(width: 24, height: 24)
    }
}
