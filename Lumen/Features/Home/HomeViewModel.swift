import Foundation
import Observation
import SwiftData

// MARK: - Home View Model

@MainActor
@Observable
final class HomeViewModel {

    private let homeService: HomeService
    private let deviceService: DeviceService
    private let stateStore: DeviceStateStore
    private let sceneService: SceneService?

    var isShowingAddRoom = false
    var isShowingOnboarding = false
    var error: (any Error)?

    init(homeService: HomeService, deviceService: DeviceService, stateStore: DeviceStateStore, sceneService: SceneService? = nil) {
        self.homeService = homeService
        self.deviceService = deviceService
        self.stateStore = stateStore
        self.sceneService = sceneService
    }

    // MARK: - Derived State

    var home: Home? { homeService.primaryHome }
    var hasHome: Bool { homeService.primaryHome != nil }
    var rooms: [Room] { homeService.primaryHome?.rooms.sorted { $0.name < $1.name } ?? [] }
    var reachableDeviceCount: Int { stateStore.reachableCount }
    var totalPlannedCount: Int { homeService.primaryHome?.totalDeviceCount ?? 0 }
    var installedDeviceCount: Int { homeService.primaryHome?.installedDeviceCount ?? 0 }

    // MARK: - Actions

    func load() {
        do {
            try homeService.load()
            deviceService.syncLocalPreviewDevices(from: homeService.primaryHome)
            isShowingOnboarding = !homeService.isLoaded || homeService.primaryHome == nil
        } catch {
            self.error = error
        }
    }

    func createHome(name: String) {
        do {
            try homeService.createHome(name: name)
            isShowingOnboarding = false
            isShowingAddRoom = false
        } catch {
            self.error = error
        }
    }

    func renameHome(to name: String) {
        guard let home = homeService.primaryHome else { return }
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        try? homeService.updateHome(home, name: cleaned)
    }

    func addRoom(name: String, type: RoomType, level: Int? = nil) {
        guard let home = homeService.primaryHome else { return }
        do {
            try homeService.addRoom(to: home, name: name, type: type, level: level)
            isShowingAddRoom = false
        } catch {
            self.error = error
        }
    }

    func executeScene(_ scene: Scene) async {
        guard let sceneService = sceneService else { return }
        do {
            try await sceneService.execute(scene)
        } catch {
            self.error = error
        }
    }

    func makeRoomViewModel() -> RoomViewModel {
        RoomViewModel(homeService: homeService, deviceService: deviceService, stateStore: stateStore)
    }
}
