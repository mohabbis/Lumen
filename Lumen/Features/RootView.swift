import SwiftUI
import SwiftData

// MARK: - Root View
// Owns tab/sidebar structure and bootstraps services on appear.
// No business logic — that lives in ViewModels and Services.

struct RootView: View {

    @Environment(AppState.self)    private var appState
    @Environment(HomeService.self) private var homeService
    @Environment(DeviceService.self) private var deviceService
    @Environment(DeviceStateStore.self) private var stateStore
    @Environment(SceneService.self) private var sceneService
    @Environment(SensorObservationService.self) private var sensorService
    @Environment(LocationService.self) private var locationService
    @Environment(\.modelContext)   private var modelContext
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        @Bindable var state = appState

        Group {
            if sizeClass == .regular {
                iPadLayout(state: _state)
            } else {
                iPhoneLayout(state: _state)
            }
        }
        .tint(Color("MuhaBrown"))
        .task { await bootstrap() }
    }

    // MARK: - iPhone Layout (TabView)

    @ViewBuilder
    private func iPhoneLayout(state: Bindable<AppState>) -> some View {
        TabView(selection: state.selectedTab) {
            NavigationStack {
                HomeDashboardView(viewModel: makeHomeVM())
            }
            .tabItem { Label(AppState.Tab.home.label, systemImage: AppState.Tab.home.systemImage) }
            .tag(AppState.Tab.home)

            NavigationStack {
                RoomListView(viewModel: makeRoomVM())
            }
            .tabItem { Label(AppState.Tab.rooms.label, systemImage: AppState.Tab.rooms.systemImage) }
            .tag(AppState.Tab.rooms)

            NavigationStack {
                DeviceListView(viewModel: makeDeviceVM())
            }
            .tabItem { Label(AppState.Tab.intel.label, systemImage: AppState.Tab.intel.systemImage) }
            .tag(AppState.Tab.intel)

            NavigationStack {
                SceneListView(viewModel: SceneViewModel(sceneService: sceneService))
            }
            .tabItem { Label(AppState.Tab.auto.label, systemImage: AppState.Tab.auto.systemImage) }
            .tag(AppState.Tab.auto)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label(AppState.Tab.settings.label, systemImage: AppState.Tab.settings.systemImage) }
            .tag(AppState.Tab.settings)
        }
    }

    // MARK: - iPad Layout (NavigationSplitView)

    @ViewBuilder
    private func iPadLayout(state: Bindable<AppState>) -> some View {
        NavigationSplitView {
            List {
                ForEach(AppState.Tab.allCases, id: \.self) { tab in
                    Button {
                        appState.selectedTab = tab
                    } label: {
                        Label(tab.label, systemImage: tab.systemImage)
                            .foregroundStyle(appState.selectedTab == tab ? Color("MuhaBrown") : .primary)
                    }
                    .listRowBackground(
                        appState.selectedTab == tab
                            ? Color("MuhaBrown").opacity(0.1)
                            : Color.clear
                    )
                }
            }
            .navigationTitle("Lumen")
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            NavigationStack {
                iPadDetail(for: appState.selectedTab)
            }
        }
    }

    @ViewBuilder
    private func iPadDetail(for tab: AppState.Tab) -> some View {
        switch tab {
        case .home:
            HomeDashboardView(viewModel: makeHomeVM())
        case .rooms:
            RoomListView(viewModel: makeRoomVM())
        case .intel:
            DeviceListView(viewModel: makeDeviceVM())
        case .auto:
            SceneListView(viewModel: SceneViewModel(sceneService: sceneService))
        case .settings:
            SettingsView()
        }
    }

    // MARK: - View Model Factories

    private func makeHomeVM() -> HomeViewModel {
        HomeViewModel(homeService: homeService, deviceService: deviceService, stateStore: stateStore)
    }

    private func makeRoomVM() -> RoomViewModel {
        RoomViewModel(homeService: homeService, deviceService: deviceService, stateStore: stateStore)
    }

    private func makeDeviceVM() -> DeviceViewModel {
        DeviceViewModel(deviceService: deviceService, stateStore: stateStore)
    }

    // MARK: - Bootstrap

    private func bootstrap() async {
        stateStore.onDevicesDiscovered = { [sensorService] devices in
            sensorService.beginObserving(devices)
        }
        stateStore.onDevicesRemoved = { [sensorService] deviceIDs in
            sensorService.cancelObservations(forDeviceIDs: deviceIDs)
        }
        if !homeService.isLoaded {
            try? homeService.load()
        }
        if appState.enableLocalPreviewControls {
            deviceService.syncLocalPreviewDevices(from: homeService.primaryHome)
        }
        try? sceneService.seedDefaultScenesIfNeeded()
        
        // Request notification permissions for automation alerts
        await NotificationService.shared.requestNotificationPermissions()
        
        // Start geofence event monitoring
        sceneService.startMonitoringGeofenceEvents(from: locationService)
        
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            let hkBridge = HomeKitBridge()
            deviceService.registerBridge(hkBridge)
        }
    }
}
