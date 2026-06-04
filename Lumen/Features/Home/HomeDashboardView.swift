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

    private var timeOfDay: TimeOfDay { .current }

    var body: some View {
        ZStack {
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
        .onAppear {
            viewModel.load()
            locationService.requestLocationPermission()
            locationService.startMonitoringLocation()
            if let home = viewModel.home, let lat = home.latitude, let lon = home.longitude {
                locationService.updateHomeCoordinates(latitude: lat, longitude: lon)
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
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 48)
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
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if locationService.isAtHome {
                    Text("Welcome Home,")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                } else {
                    Text(timeOfDay.greeting + ",")
                        .font(.system(size: 36, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                }
                Text(viewModel.home?.name ?? "Home")
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundStyle(.white)
                    .onLongPressGesture {
                        renameText = viewModel.home?.name ?? ""
                        isRenamingHome = true
                    }
            }

            Text(homeStatusSubtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.5))
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

            let columns = sizeClass == .regular
                ? [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
                : [GridItem(.flexible()), GridItem(.flexible())]

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.rooms.prefix(4), id: \.id) { room in
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
        switch timeOfDay {
        case .dawn, .morning:
            if let morningScene = findScene(named: "Morning") {
                Task { await viewModel.executeScene(morningScene) }
            }
        case .afternoon:
            break // No automation suggested for afternoon; user navigates manually.
        case .evening:
            if let eveningScene = findScene(named: "Evening") {
                Task { await viewModel.executeScene(eveningScene) }
            }
        case .night:
            if let sleepScene = findScene(named: "Sleep") {
                Task { await viewModel.executeScene(sleepScene) }
            }
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
