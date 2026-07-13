import Foundation
import XCTest
@testable import Lumen

// MARK: - Shared Test Doubles
//
// Enablers for the device / bridge / sensor test surface. Before these existed
// there was no `SmartHomeBridge` test double in the suite, so every device test
// ran through the `.localPreview` short-circuit and the real-hardware routing
// path was never exercised. These fakes let tests drive discovery, live state
// streams, and action forwarding deterministically.

// MARK: Configurable SmartDevice

/// A `SmartDevice` whose `bridgeID` and `reachability` are configurable.
/// `LocalSmartDevice` hard-codes both (`.localPreview` / `.reachable`), so it
/// can't stand in for a real bridged device in routing tests.
struct TestSmartDevice: SmartDevice {
    let id: DeviceID
    let displayName: String
    let roomName: String?
    let reachability: DeviceReachability
    let bridgeID: BridgeID
    let category: DeviceCategory
    let capabilities: [any DeviceCapability]

    init(
        id: DeviceID = UUID(),
        displayName: String = "Test Device",
        roomName: String? = nil,
        reachability: DeviceReachability = .reachable,
        bridgeID: BridgeID,
        category: DeviceCategory = .lighting,
        capabilities: [any DeviceCapability] = [
            LocalPreviewCapability(capabilityID: .onOff, displayName: "Power", isReadOnly: false)
        ]
    ) {
        self.id = id
        self.displayName = displayName
        self.roomName = roomName
        self.reachability = reachability
        self.bridgeID = bridgeID
        self.category = category
        self.capabilities = capabilities
    }
}

// MARK: Fake SmartHomeBridge

/// In-memory `SmartHomeBridge` for tests. Records executed actions, vends a
/// controllable device set, and exposes a live state stream that tests feed via
/// `emit(_:)`. Mirrors the continuation-storage pattern used by `HomeKitBridge`.
actor FakeSmartHomeBridge: SmartHomeBridge {
    let id: BridgeID
    let displayName: String

    private var _status: BridgeStatus
    var status: BridgeStatus { _status }

    private var authorizeError: (any Error)?
    private var executeError: (any Error)?
    private(set) var executedActions: [SceneActionSnapshot] = []

    /// True once `deviceStateStream()` has been called and the continuation is
    /// live — tests wait on this before `emit(_:)` so yields aren't dropped.
    private(set) var isStreamOpen = false

    private var devices: [DeviceID: any SmartDevice]
    private var streamContinuation: AsyncStream<DeviceStateChange>.Continuation?

    init(
        id: BridgeID,
        displayName: String = "Fake Bridge",
        status: BridgeStatus = .authorized,
        devices: [any SmartDevice] = [],
        authorizeError: (any Error)? = nil,
        executeError: (any Error)? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self._status = status
        self.devices = Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
        self.authorizeError = authorizeError
        self.executeError = executeError
    }

    /// Replaces (or inserts) a device so `device(withID:)` reflects new state —
    /// used to simulate a live state change before calling `emit(_:)`.
    func upsert(_ device: any SmartDevice) {
        devices[device.id] = device
    }

    /// Pushes a state change through the live stream opened by `deviceStateStream()`.
    func emit(_ change: DeviceStateChange) {
        streamContinuation?.yield(change)
    }

    // MARK: SmartHomeBridge

    func authorize() async throws {
        if let authorizeError { throw authorizeError }
    }

    func discover() async throws -> [any SmartDevice] {
        Array(devices.values)
    }

    func deviceStateStream() -> AsyncStream<DeviceStateChange> {
        AsyncStream { continuation in
            self.streamContinuation = continuation
            self.isStreamOpen = true
        }
    }

    func device(withID id: DeviceID) async -> (any SmartDevice)? {
        devices[id]
    }

    func executeAction(_ action: SceneActionSnapshot) async throws {
        if let executeError { throw executeError }
        executedActions.append(action)
    }

    func shutdown() async {
        streamContinuation?.finish()
        streamContinuation = nil
    }
}

// MARK: Stream-driven sensor capabilities

/// A `MotionCapability` backed by a caller-supplied `AsyncStream<Bool>` so tests
/// can push motion events on demand.
struct FakeMotionCapability: MotionCapability {
    let capabilityID: CapabilityID = .motion
    let displayName = "Motion"
    let isReadOnly = true
    var motionDetected: Bool { get async { false } }
    var lastMotionDate: Date? { get async { nil } }
    let motionStream: AsyncStream<Bool>
}

/// A `ContactCapability` backed by a caller-supplied `AsyncStream<ContactState>`.
struct FakeContactCapability: ContactCapability {
    let capabilityID: CapabilityID = .contact
    let displayName = "Contact"
    let isReadOnly = true
    var contactState: ContactState { get async { .closed } }
    let contactStream: AsyncStream<ContactState>
}

/// A sensor device carrying fake motion/contact capabilities for
/// `SensorObservationService` tests.
struct SensorTestDevice: SmartDevice {
    let id: DeviceID
    var displayName: String = "Sensor"
    var roomName: String? = nil
    let reachability: DeviceReachability = .reachable
    let bridgeID: BridgeID = .homeKit
    let category: DeviceCategory = .sensors
    let capabilities: [any DeviceCapability]
}

// MARK: - Async polling helper

extension XCTestCase {
    /// Polls `condition` on the main actor until it returns true or `timeout`
    /// elapses. Sleeps briefly between checks so background `@MainActor` tasks
    /// (bridge discovery, sensor stream consumers) get a chance to run.
    @MainActor
    func waitUntil(
        timeout: TimeInterval = 2.0,
        _ condition: () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() {
            if Date() > deadline { return }
            try? await Task.sleep(nanoseconds: 2_000_000) // 2ms
        }
    }

    /// A short fixed pause used by negative assertions ("nothing else was
    /// recorded after cancel") where there is no positive condition to await.
    func settle(_ seconds: TimeInterval = 0.1) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }

    /// Waits until a `FakeSmartHomeBridge` has opened its live state stream, so a
    /// subsequent `emit(_:)` is delivered rather than dropped on a nil continuation.
    func waitForStreamOpen(_ bridge: FakeSmartHomeBridge, timeout: TimeInterval = 2.0) async {
        let deadline = Date().addingTimeInterval(timeout)
        while await !bridge.isStreamOpen {
            if Date() > deadline { return }
            try? await Task.sleep(nanoseconds: 2_000_000)
        }
    }
}
