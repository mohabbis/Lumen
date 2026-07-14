import Foundation
import Observation
import SwiftData

// MARK: - Local Device Config Provider
// A tiny thread-safe box the LocalNetworkBridge reads its configs from. The
// bridge is an actor whose `@Sendable` config closure may run off the main
// actor, so the snapshot lives behind a lock rather than on the main-actor
// service directly.

final class LocalDeviceConfigProvider: @unchecked Sendable {
    private let lock = NSLock()
    private var configs: [LocalDeviceConfig] = []

    func update(_ newConfigs: [LocalDeviceConfig]) {
        lock.lock(); defer { lock.unlock() }
        configs = newConfigs
    }

    func snapshot() -> [LocalDeviceConfig] {
        lock.lock(); defer { lock.unlock() }
        return configs
    }
}

// MARK: - Local Device Service
// Owns LocalDeviceRecord CRUD and keeps the LocalNetworkBridge in sync with it.
// On any change it republishes the config snapshot and re-registers the bridge
// through DeviceService, so added devices are discovered and removed devices are
// pruned (re-registration tears down the old bridge's devices first).

@MainActor
@Observable
final class LocalDeviceService {

    private let modelContext: ModelContext
    private let deviceService: DeviceService
    private let provider = LocalDeviceConfigProvider()
    private let transportFactory: @Sendable (LocalDeviceKind) -> any LocalDeviceTransport

    var error: (any Error)?

    init(
        modelContext: ModelContext,
        deviceService: DeviceService,
        transportFactory: @escaping @Sendable (LocalDeviceKind) -> any LocalDeviceTransport = { _ in ShellyGen2Transport() }
    ) {
        self.modelContext = modelContext
        self.deviceService = deviceService
        self.transportFactory = transportFactory
    }

    // MARK: - Bridge Lifecycle

    /// Registers (or re-registers) the local-network bridge with the current set
    /// of records. Safe to call repeatedly — the previous bridge is unregistered
    /// first, which removes its now-stale devices from the state store.
    func reloadBridge() async {
        refreshSnapshot()
        await deviceService.unregisterBridge(.localNetwork)
        let provider = provider
        let factory = transportFactory
        deviceService.registerBridge(
            LocalNetworkBridge(configProvider: { provider.snapshot() }, transportFactory: factory)
        )
    }

    // MARK: - CRUD

    func addDevice(
        name: String,
        address: String,
        kind: LocalDeviceKind,
        channel: Int = 0,
        roomName: String? = nil
    ) {
        let record = LocalDeviceRecord(
            displayName: name,
            roomName: roomName,
            address: address,
            kind: kind,
            channel: channel,
            category: .lighting,
            sortOrder: nextSortOrder()
        )
        modelContext.insert(record)
        persist()
    }

    func deleteDevice(_ record: LocalDeviceRecord) {
        modelContext.delete(record)
        persist()
    }

    func setAddress(_ address: String, on record: LocalDeviceRecord) {
        record.address = address.trimmingCharacters(in: .whitespacesAndNewlines)
        record.updatedAt = Date()
        persist()
    }

    func setKind(_ kind: LocalDeviceKind, on record: LocalDeviceRecord) {
        record.kind = kind
        record.updatedAt = Date()
        persist()
    }

    func setChannel(_ channel: Int, on record: LocalDeviceRecord) {
        record.channel = max(0, channel)
        record.updatedAt = Date()
        persist()
    }

    // MARK: - Private

    private func persist() {
        do {
            try modelContext.save()
            Task { await reloadBridge() }
        } catch {
            self.error = error
        }
    }

    private func refreshSnapshot() {
        provider.update(fetchRecords().map(\.config))
    }

    private func fetchRecords() -> [LocalDeviceRecord] {
        let descriptor = FetchDescriptor<LocalDeviceRecord>(
            sortBy: [SortDescriptor(\.sortOrder), SortDescriptor(\.createdAt)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func nextSortOrder() -> Int {
        (fetchRecords().map(\.sortOrder).max() ?? -1) + 1
    }
}
