import SwiftUI
import SwiftData

// MARK: - Home Dashboard View
// Matches the "Awareness" mode shown on lumen.muharafiq.com
// Location-aware: shows "Welcome Home" when at home, "Away Mode" otherwise

struct HomeDashboardView: View {

    @State var viewModel: HomeViewModel
    @Query private var scenes: [Scene]
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(LocationService.self) private var locationService
    @State private var isRenamingHome = false
    @State private var renameText = ""
    @State private var isShowingReasoning = false
    @State private var isShowingAction = false
    @State private var statusOverlayID = UUID()
    @State private var isStatusOverlayVisible = false

    private var timeOfDay: TimeOfDay { .current }
    private var isRegularLayout: Bool { sizeClass == .regular }
    private var dashboardMaxWidth: CGFloat { isRegularLayout ? 1120 : .infinity }
    private var dashboardHorizontalPadding: CGFloat { isRegularLayout ? 44 : 20 }
    private var dashboardTopPadding: CGFloat { isRegularLayout ? 28 : 8 }
    private var greetingTitleSize: CGFloat { isRegularLayout ? 48 : 36 }
    private var roomLimit: Int { isRegularLayout ? 6 : 4 }

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
                                          removal: .move(edge: .bottom).combined(with: .opacity)))
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
        .sheet(isPresented: $isShowingReasoning) {
            LumenReasoningView(
                reasoning: reasoning,
                onApply: { isShowingAction = true },
                onDismiss: { isShowingReasoning = false }
            )
        }
        .sheet(isPresented: $isShowingAction) {
            if let sceneName = suggestedSceneName, let scene = findScene(named: sceneName) {
                LumenActionView(
                    scene: scene,
                    onConfirm: { handleLumenSuggestion() },
                    onCancel: { isShowingAction = false }
                )
            } else {
                // Fallback if the suggested scene becomes unavailable mid-flow.
                VStack(spacing: 12) {
                    Text("Scene not available")
                        .font(.title2)
                        .foregroundStyle(.white)
                    Button("Done") {
                        isShowingAction = false
                        isShowingReasoning = false
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color(hex: "#C49A6C"), in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(24)
                .background(Color(hex: "#0E0819").ignoresSafeArea())
            }
        }
        .onAppear {
            viewModel.load()
            locationService.requestLocationPermission()
            locationService.startMonitoringLocation()
            if let home = viewModel.home, let lat = home.latitude, let lon = home.longitude {
                locationService.updateHomeCoordinates(latitude: lat, longitude: lon)
            }
            statusOverlayID = UUID()
            isStatusOverlayVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) { isStatusOverlayVisible = false }
            }
        }
        .onChange(of: locationService.isAtHome) { _, _ in
            statusOverlayID = UUID()
            isStatusOverlayVisible = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) { isStatusOverlayVisible = false }
            }
        }
        .onDisappear {
            locationService.stopMonitoringLocation()
        }
    }

    // MARK: - Ambient Background (time-of-day gradient)

    private var ambientBackground: some View {
        ZStack {
            if locationService.isAtHome {
                Color(hex: "#0E0819")
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
            compactStats
            NowNextCard(now: timeOfDay)
            if !viewModel.rooms.isEmpty {
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
                    compactStats
                    NowNextCard(now: timeOfDay)
                    if !viewModel.rooms.isEmpty {
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
                    .foregroundStyle(locationService.isAtHome ? Color(hex: "#C49A6C") : Color.white.opacity(0.35))
                Image(systemName: locationService.isAtHome ? "house.fill" : "location.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(locationService.isAtHome ? Color(hex: "#C49A6C") : Color.white.opacity(0.35))
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

    // MARK: - Lumen Noticed Section

    private var lumenNoticedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("LUMEN NOTICED")
                .font(.system(size: 10, weight: .semibold))
                .tracking(2.5)
                .foregroundStyle(Color.white.opacity(0.35))

            VStack(spacing: 8) {
                LumenNoticedCard(
                    message: noticedMessage,
                    suggestion: noticedSuggestion,
                    icon: "sparkles",
                    action: { isShowingReasoning = true }
                )
            }
        }
    }

    // MARK: - Lumen Suggestion Handler

    private func handleLumenSuggestion() {
        isShowingAction = false
        isShowingReasoning = false

        // Execute the same scene the Action sheet displayed — single source of truth.
        if let sceneName = suggestedSceneName, let scene = findScene(named: sceneName) {
            Task { await viewModel.executeScene(scene) }
        }
    }

    private func findScene(named name: String) -> Scene? {
        scenes.first { $0.name.lowercased() == name.lowercased() }
    }

    private var suggestedSceneName: String? {
        let candidate: String?
        switch timeOfDay {
        case .dawn, .morning: candidate = "Morning"
        case .afternoon:      candidate = nil
        case .evening:        candidate = "Evening"
        case .night:          candidate = "Sleep"
        }
        guard let name = candidate, let scene = findScene(named: name) else { return nil }
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
            suggestedSceneName: suggestedSceneName
        ).reasoning
    }

    private var noticedMessage: String {
        switch timeOfDay {
        case .dawn:      return "It's early. Your home is quiet and the lights are dim."
        case .morning:   return "Good morning. All devices are ready for the day."
        case .afternoon: return "Afternoon light is bright. Consider lowering your shades."
        case .evening:   return "Sunset detected. Warm lighting mode is available."
        case .night:     return "Your home is winding down. All devices are in standby."
        }
    }

    private var noticedSuggestion: String {
        switch timeOfDay {
        case .dawn:      return "Run Morning scene"
        case .morning:   return "Check room status"
        case .afternoon: return "Adjust brightness"
        case .evening:   return "Run Evening scene"
        case .night:     return "Prepare night mode"
        }
    }
}

private struct StatusOverlay: View {
    let isAtHome: Bool
    let id: UUID
    @State private var animate = false
    var body: some View {
        VStack {
            Spacer()
            if isAtHome {
                Text("🏠 Welcome Home!")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color(hex: "#C49A6C"))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.12))
                            .blur(radius: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 20, y: 4)
                    .scaleEffect(animate ? 1 : 0.85)
                    .opacity(animate ? 1 : 0.5)
                    .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { animate = true } }
            } else {
                Text("🌙 Away Mode")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .padding(.horizontal, 36)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.white.opacity(0.09))
                            .blur(radius: 0.5)
                    )
                    .shadow(color: .black.opacity(0.14), radius: 20, y: 4)
                    .scaleEffect(animate ? 1 : 0.85)
                    .opacity(animate ? 1 : 0.5)
                    .onAppear { withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { animate = true } }
            }
            Spacer()
        }
        .id(id)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.easeInOut(duration: 0.7), value: isAtHome)
        .ignoresSafeArea()
    }
}

private struct LumenNoticedCard: View {
    let message: String
    let suggestion: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#C49A6C"))
                    Text("Lumen noticed")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color(hex: "#C49A6C"))
                }

                Text(message)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                        Text("Suggested by Lumen")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.white.opacity(0.28))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "#C49A6C"))
                }
            }
            .padding(18)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}