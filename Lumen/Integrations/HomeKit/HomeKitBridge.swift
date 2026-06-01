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

    // MARK: - SmartHomeBridge

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
                let device = HomeKitDevice(accessory: accessory, homeName: home.name)
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
        deviceMap[id]
    }

    func executeAction(_ action: SceneActionSnapshot) async throws {
        guard let device = deviceMap[action.deviceID] else {
            throw AppError.deviceNotFound(action.deviceID)
        }
        try await device.execute(action)
    }

    func shutdown() async {
        stateStreamContinuation?.finish()
        stateStreamContinuation = nil
        delegateAdapter = nil
        status = .idle
    }

    // MARK: - Internal — called from delegate on nonisolated context

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
}

// MARK: - HMHomeManager Delegate Adapter
// Bridges Obj-C delegate callbacks into the actor world.

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
