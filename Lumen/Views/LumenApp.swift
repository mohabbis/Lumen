import SwiftUI
import SwiftData

@main
struct LumenApp: App {

    // Container is a stored property — created exactly once at app init.
    // Never constructed inside body or any computed property.
    private let container: ModelContainer

    @State private var appState    = AppState()
    @State private var homeService: HomeService
    @State private var deviceService: DeviceService
    @State private var stateStore  = DeviceStateStore()
    @State private var sceneService: SceneService
    @State private var sensorService = SensorObservationService()
    @State private var locationService = LocationService()
    @State private var remoteService = RemoteService()
    @State private var localDeviceService: LocalDeviceService
    @State private var nfcService: NFCService

    init() {
        let c = PersistenceCoordinator.makeContainer()
        container = c

        let ctx = c.mainContext
        let store = DeviceStateStore()
        let home  = HomeService(modelContext: ctx)
        let dev   = DeviceService(modelContext: ctx, stateStore: store)
        let scene = SceneService(modelContext: ctx, deviceService: dev)
        let local = LocalDeviceService(modelContext: ctx, deviceService: dev)
        let nfc   = NFCService(sceneService: scene, modelContext: ctx)

        _stateStore    = State(wrappedValue: store)
        _homeService   = State(wrappedValue: home)
        _deviceService = State(wrappedValue: dev)
        _sceneService  = State(wrappedValue: scene)
        _localDeviceService = State(wrappedValue: local)
        _nfcService    = State(wrappedValue: nfc)
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(homeService)
                .environment(deviceService)
                .environment(stateStore)
                .environment(sceneService)
                .environment(sensorService)
                .environment(locationService)
                .environment(remoteService)
                .environment(localDeviceService)
                .environment(nfcService)
                .onOpenURL { handleIncomingURL($0) }
        }
        .modelContainer(container)
    }

    /// Deep links use `lumen://scene/<uuid>` and only queue for approval — never execute.
    private func handleIncomingURL(_ url: URL) {
        guard url.scheme == "lumen",
              url.host == "scene",
              let sceneIDString = url.pathComponents.last,
              let sceneID = UUID(uuidString: sceneIDString) else {
            return
        }
        appState.pendingExternalSceneID = sceneID
        appState.selectedTab = .auto
    }
}
