import Foundation

// MARK: - Bridge Identity

struct BridgeID: Hashable, Sendable, CustomStringConvertible, Codable {
    let rawValue: String
    init(_ value: String) { rawValue = value }
    var description: String { rawValue }

    // HomeKit is the one real hardware bridge. Matter accessories are reached
    // through it too: iOS surfaces them as HomeKit accessories, so they arrive
    // via HomeKitBridge rather than needing a bridge of their own.
    static let homeKit = BridgeID("homekit")
}

// MARK: - Bridge Status

enum BridgeStatus: Sendable {
    case idle
    case connecting
    case connected
    case authorized
    case authorizationRequired
    case denied
    case error(any Error)

    var isOperational: Bool {
        if case .authorized = self { return true }
        return false
    }

    var displayName: String {
        switch self {
        case .idle:                   return "Idle"
        case .connecting:             return "Connecting…"
        case .connected:              return "Connected"
        case .authorized:             return "Active"
        case .authorizationRequired:  return "Needs Permission"
        case .denied:                 return "Access Denied"
        case .error:                  return "Error"
        }
    }
}

// MARK: - Scene Action Snapshot
// A value-type snapshot sent to bridges for execution.
// Bridges never receive SwiftData model references.

struct SceneActionSnapshot: Sendable {
    let deviceID: DeviceID
    let capabilityID: CapabilityID
    let payload: ActionPayload
}

enum ActionPayload: Sendable {
    case bool(Bool)
    case double(Double)
    case int(Int)
    case colorHSB(hue: Double, saturation: Double, brightness: Double)
    case temperature(Measurement<UnitTemperature>)
    case hvacMode(HVACMode)
    case lockState(LockState)
}

// MARK: - Smart Home Bridge Protocol

protocol SmartHomeBridge: Actor {
    nonisolated var id: BridgeID { get }
    nonisolated var displayName: String { get }
    var status: BridgeStatus { get }

    /// Request authorization. Throws if denied.
    func authorize() async throws

    /// Discover all currently reachable devices.
    func discover() async throws -> [any SmartDevice]

    /// Async stream of state change events from this bridge.
    func deviceStateStream() -> AsyncStream<DeviceStateChange>

    /// Fetch an individual device by ID, reflecting latest known state.
    func device(withID id: DeviceID) async -> (any SmartDevice)?

    /// Execute a single atomic action.
    func executeAction(_ action: SceneActionSnapshot) async throws

    /// Graceful teardown of subscriptions and connections.
    func shutdown() async
}
