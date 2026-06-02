import Foundation
import Observation

// MARK: - Room View Model

@MainActor
@Observable
final class RoomViewModel {

    private let homeService: HomeService
    private let deviceService: DeviceService
    private let stateStore: DeviceStateStore

    var isShowingAddRoom = false
    var error: (any Error)?

    init(homeService: HomeService, deviceService: DeviceService, stateStore: DeviceStateStore) {
        self.homeService = homeService
        self.deviceService = deviceService
        self.stateStore = stateStore
    }

    // MARK: - Derived State

    var home: Home? { homeService.primaryHome }

    var rooms: [Room] {
        homeService.primaryHome?.rooms.sorted { $0.name < $1.name } ?? []
    }

    func liveDevices(in room: Room) -> [any SmartDevice] {
        stateStore.devices(inRoom: room.name)
    }

    // MARK: - Actions

    func addRoom(name: String, type: RoomType, level: Int? = nil) {
        guard let home = homeService.primaryHome else { return }
        do {
            try homeService.addRoom(to: home, name: name, type: type, level: level)
            isShowingAddRoom = false
        } catch {
            self.error = error
        }
    }

    func deleteRoom(_ room: Room) {
        do {
            try homeService.deleteRoom(room)
        } catch {
            self.error = error
        }
    }

    func updateRoom(_ room: Room, name: String, type: RoomType) {
        do {
            try homeService.updateRoom(room, name: name, type: type)
        } catch {
            self.error = error
        }
    }

    func addDevice(name: String, type: DeviceType, to room: Room) {
        do {
            try deviceService.addPlannedDevice(name: name, type: type, to: room)
        } catch {
            self.error = error
        }
    }

    func deleteDevice(_ device: PlannedDevice) {
        do {
            try deviceService.deletePlannedDevice(device)
        } catch {
            self.error = error
        }
    }

    func makeDeviceViewModel() -> DeviceViewModel {
        DeviceViewModel(deviceService: deviceService, stateStore: stateStore)
    }
}
