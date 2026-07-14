import Foundation

// MARK: - Local Network Bridge
// A second real SmartHomeBridge alongside HomeKit, for devices Apple Home can't
// see. It reaches user-configured LAN devices over their local HTTP APIs. Unlike
// HomeKit there is no OS authorization gate and (today) no push channel — local
// HTTP devices are polled/read on demand, so the state stream stays open for a
// future poller but does not emit unprompted.
//
// The bridge is intentionally driven by injected `[LocalDeviceConfig]` value
// types and a transport factory, so the whole integration is testable without a
// network. Persisting configs + a Settings surface to author them is the next
// step; this is the engine that surface will drive.

actor LocalNetworkBridge: SmartHomeBridge {

    let id: BridgeID = .localNetwork
    let displayName: String = "Local Network"

    private(set) var status: BridgeStatus = .idle

    private let configProvider: @Sendable () -> [LocalDeviceConfig]
    private let transportFactory: @Sendable (LocalDeviceKind) -> any LocalDeviceTransport

    private var configsByID: [DeviceID: LocalDeviceConfig] = [:]
    private var reachabilityByID: [DeviceID: DeviceReachability] = [:]
    private var stateStreamContinuation: AsyncStream<DeviceStateChange>.Continuation?

    init(
        configProvider: @escaping @Sendable () -> [LocalDeviceConfig],
        transportFactory: @escaping @Sendable (LocalDeviceKind) -> any LocalDeviceTransport = { _ in ShellyGen2Transport() }
    ) {
        self.configProvider = configProvider
        self.transportFactory = transportFactory
    }

    /// No OS permission gate for LAN control — becomes authorized immediately.
    func authorize() async throws {
        status = .authorized
    }

    func discover() async throws -> [any SmartDevice] {
        guard status.isOperational else {
            throw AppError.bridgeAuthorizationDenied(.localNetwork)
        }

        var result: [LocalNetworkDevice] = []
        for config in configProvider() {
            configsByID[config.id] = config
            let transport = transportFactory(config.kind)
            // Probe reachability without failing discovery: an offline device
            // still lists, marked unreachable, exactly like HomeKit.
            let reachable = (try? await transport.read(from: config.target)) != nil
            let reachability: DeviceReachability = reachable ? .reachable : .unreachable
            reachabilityByID[config.id] = reachability
            result.append(LocalNetworkDevice(config: config, transport: transport, reachability: reachability))
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
        guard let config = configsByID[id] else { return nil }
        let reachability = reachabilityByID[id] ?? .unknown
        return LocalNetworkDevice(
            config: config,
            transport: transportFactory(config.kind),
            reachability: reachability
        )
    }

    func executeAction(_ action: SceneActionSnapshot) async throws {
        guard let config = configsByID[action.deviceID] else {
            throw AppError.deviceNotFound(action.deviceID)
        }
        let device = LocalNetworkDevice(config: config, transport: transportFactory(config.kind))
        try await device.execute(action)
        // Local HTTP has no push; echo the change so the store refreshes state.
        emitStateChange(DeviceStateChange(deviceID: action.deviceID, capabilityID: action.capabilityID))
    }

    func shutdown() async {
        stateStreamContinuation?.finish()
        stateStreamContinuation = nil
        configsByID.removeAll()
        reachabilityByID.removeAll()
        status = .idle
    }

    // MARK: - Private

    func emitStateChange(_ change: DeviceStateChange) {
        stateStreamContinuation?.yield(change)
    }

    private func clearStreamContinuation() {
        stateStreamContinuation = nil
    }
}
