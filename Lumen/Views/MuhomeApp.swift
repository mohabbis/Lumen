import SwiftUI
import SwiftData

@main
struct MuhomeApp: App {

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

    init() {
        let c = PersistenceCoordinator.makeContainer()
        container = c

        let ctx = c.mainContext
        let store = DeviceStateStore()
        let home  = HomeService(modelContext: ctx)
        let dev   = DeviceService(modelContext: ctx, stateStore: store)
        let scene = SceneService(modelContext: ctx, deviceService: dev)

        _stateStore    = State(wrappedValue: store)
        _homeService   = State(wrappedValue: home)
        _deviceService = State(wrappedValue: dev)
        _sceneService  = State(wrappedValue: scene)
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
        }
        .modelContainer(container)
    }
}
