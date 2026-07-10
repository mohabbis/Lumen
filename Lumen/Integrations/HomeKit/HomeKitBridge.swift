import Foundation
import HomeKit

// MARK: - HomeKit Bridge

actor HomeKitBridge: SmartHomeBridge {

    let id: BridgeID = .homeKit
    let displayName: String = "HomeKit"

    private(set) var status: BridgeStatus = .idle

    private let homeManager = HMHomeManager()
    private var hmHomes: [HMHome] = []
    private var deviceMap: [DeviceID: HomeKitDevice] = [:]
    private var stateStreamContinuation: AsyncStream<DeviceStateChange>.Continuation?
    private var delegateAdapter: HomeKitManagerDelegateAdapter?
    private var accessoryObservers: [UUID: HomeKitAccessoryObserver] = [:]

    private var motionContinuations: [DeviceID: AsyncStream<Bool>.Continuation] = [:]
    private var contactContinuations: [DeviceID: AsyncStream<ContactState>.Continuation] = [:]

    func authorize() async throws {
        status = .connecting

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let adapter = HomeKitManagerDelegateAdapter { [weak self] result in
                Task {
                    switch result {
                    case .success(let homes):
                        await self?.handleManagerReady(homes: homes)
                        continuation.resume()
                    case .failure:
                        await self?.setStatus(.denied)
                        continuation.resume(throwing: AppError.bridgeAuthorizationDenied(.homeKit))
                    }
                }
            }
            delegateAdapter = adapter
            homeManager.delegate = adapter
        }
    }

    func discover() async throws -> [any SmartDevice] {
        guard status.isOperational else {
            throw AppError.bridgeAuthorizationDenied(.homeKit)
        }

        var result: [HomeKitDevice] = []
        for home in hmHomes {
            for accessory in home.accessories {
                await subscribeToUpdates(for: accessory)
                let streams = makeStreams(for: accessory.uniqueIdentifier)
                let device = HomeKitDevice(accessory: accessory, homeName: home.name, streams: streams)
                deviceMap[device.id] = device
                result.append(device)
            }
        }
        return result
    }

    func deviceStateStream() -> AsyncStream<DeviceStateChange> {
        AsyncStream { continuation in
            self.stateStreamContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.clearStreamContinuation() }
            }
        }
    }

    func device(withID id: DeviceID) async -> (any SmartDevice)? {
        guard let existing = deviceMap[id] else { return nil }
        let streams = makeStreams(for: id)
        let refreshed = HomeKitDevice(
            accessory: existing.accessoryReference,
            homeName: existing.homeName,
            streams: streams
        )
        deviceMap[id] = refreshed
        return refreshed
    }

    func executeAction(_ action: SceneActionSnapshot) async throws {
        guard let device = deviceMap[action.deviceID] else {
            throw AppError.deviceNotFound(action.deviceID)
        }
        try await device.execute(action)
    }

    func shutdown() async {
        finishAllStreams()
        stateStreamContinuation?.finish()
        stateStreamContinuation = nil
        delegateAdapter = nil
        accessoryObservers.removeAll()
        status = .idle
    }

    func handleManagerReady(homes: [HMHome]) {
        hmHomes = homes
        status = .authorized
    }

    func setStatus(_ newStatus: BridgeStatus) {
        status = newStatus
    }

    func emitStateChange(_ change: DeviceStateChange) {
        stateStreamContinuation?.yield(change)
    }

    func clearStreamContinuation() {
        stateStreamContinuation = nil
    }

    func handleCharacteristicUpdate(accessory: HMAccessory, characteristic: HMCharacteristic) {
        let deviceID = accessory.uniqueIdentifier

        if let motion = HomeKitCharacteristicMapper.motionValue(from: characteristic) {
            motionContinuations[deviceID]?.yield(motion)
        }

        if let contact = HomeKitCharacteristicMapper.contactValue(from: characteristic) {
            contactContinuations[deviceID]?.yield(contact)
        }

        if let capabilityID = HomeKitCharacteristicMapper.capabilityID(for: characteristic.characteristicType) {
            emitStateChange(DeviceStateChange(deviceID: deviceID, capabilityID: capabilityID))
        }
    }

    private func subscribeToUpdates(for accessory: HMAccessory) async {
        let deviceID = accessory.uniqueIdentifier
        let observer = HomeKitAccessoryObserver { [weak self] accessory, characteristic in
            Task { await self?.handleCharacteristicUpdate(accessory: accessory, characteristic: characteristic) }
        }
        accessoryObservers[deviceID] = observer
        accessory.delegate = observer

        for service in accessory.services {
            for characteristic in service.characteristics
            where HomeKitCharacteristicMapper.notifiableTypes.contains(characteristic.characteristicType) {
                await enableNotifications(for: characteristic)
            }
        }
    }

    private func enableNotifications(for characteristic: HMCharacteristic) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            characteristic.enableNotification(true) { _ in
                continuation.resume()
            }
        }
    }

    private func makeStreams(for deviceID: DeviceID) -> HomeKitDeviceStreams {
        let motion = AsyncStream<Bool> { continuation in
            motionContinuations[deviceID] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeMotionContinuation(deviceID: deviceID) }
            }
        }
        let contact = AsyncStream<ContactState> { continuation in
            contactContinuations[deviceID] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { await self?.removeContactContinuation(deviceID: deviceID) }
            }
        }
        return HomeKitDeviceStreams(motion: motion, contact: contact)
    }

    private func removeMotionContinuation(deviceID: DeviceID) {
        motionContinuations.removeValue(forKey: deviceID)
    }

    private func removeContactContinuation(deviceID: DeviceID) {
        contactContinuations.removeValue(forKey: deviceID)
    }

    private func finishAllStreams() {
        motionContinuations.values.forEach { $0.finish() }
        motionContinuations.removeAll()
        contactContinuations.values.forEach { $0.finish() }
        contactContinuations.removeAll()
    }
}

private final class HomeKitManagerDelegateAdapter: NSObject, HMHomeManagerDelegate, @unchecked Sendable {

    private let onReady: @Sendable (Result<[HMHome], any Error>) -> Void
    private var didFire = false

    init(onReady: @escaping @Sendable (Result<[HMHome], any Error>) -> Void) {
        self.onReady = onReady
    }

    func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
        guard !didFire else { return }
        didFire = true
        onReady(.success(manager.homes))
    }

    func homeManager(_ manager: HMHomeManager, didUpdate status: HMHomeManagerAuthorizationStatus) {
        guard !didFire else { return }
        if status.contains(.restricted) {
            didFire = true
            onReady(.failure(AppError.bridgeAuthorizationDenied(.homeKit)))
        }
    }
}
