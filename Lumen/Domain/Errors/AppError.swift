import Foundation

// MARK: - Unified App Error Domain

enum AppError: LocalizedError {

    // Persistence
    case containerInitializationFailed(underlying: any Error)
    case migrationFailed(underlying: any Error)
    case saveContextFailed(underlying: any Error)
    case entityNotFound(type: String, id: String)

    // Bridge
    case bridgeNotFound(BridgeID)
    case bridgeAuthorizationDenied(BridgeID)
    case bridgeConnectionFailed(BridgeID, underlying: any Error)
    case bridgeDiscoveryFailed(BridgeID, underlying: any Error)

    // Device
    case deviceNotFound(DeviceID)
    case deviceUnreachable(DeviceID)
    case capabilityNotSupported(CapabilityID, deviceID: DeviceID)
    case deviceActionFailed(DeviceID, underlying: any Error)

    // Scene
    case sceneNotFound(UUID)
    case sceneExecutionPartialFailure(succeeded: Int, failed: Int)
    case sceneExecutionFailed(underlying: any Error)

    // Home
    case homeNotFound
    case homeAlreadyExists(name: String)
    case invalidConfiguration(reason: String)

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .containerInitializationFailed:
            return "Failed to initialize the database."
        case .migrationFailed:
            return "Database migration failed."
        case .saveContextFailed:
            return "Failed to save changes."
        case .entityNotFound(let type, let id):
            return "\(type) not found (ID: \(id))."
        case .bridgeNotFound(let id):
            return "Bridge '\(id)' is not registered."
        case .bridgeAuthorizationDenied(let id):
            return "Access denied for '\(id)'. Check Settings → Privacy."
        case .bridgeConnectionFailed(let id, _):
            return "Could not connect to '\(id)'."
        case .bridgeDiscoveryFailed(let id, _):
            return "Device discovery failed for '\(id)'."
        case .deviceNotFound(let id):
            return "Device not found (ID: \(id))."
        case .deviceUnreachable:
            return "Device is not responding."
        case .capabilityNotSupported(let cap, _):
            return "'\(cap.rawValue)' is not supported on this device."
        case .deviceActionFailed(_, let err):
            return "Device action failed: \(err.localizedDescription)"
        case .sceneNotFound:
            return "Scene not found."
        case .sceneExecutionPartialFailure(let s, let f):
            return "Scene ran with issues: \(s) succeeded, \(f) failed."
        case .sceneExecutionFailed:
            return "Scene execution failed."
        case .homeNotFound:
            return "No home configured."
        case .homeAlreadyExists(let name):
            return "A home named '\(name)' already exists."
        case .invalidConfiguration(let reason):
            return reason
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .bridgeAuthorizationDenied:
            return "Open Settings → Privacy & Security and grant the required access."
        case .deviceUnreachable:
            return "Check that the device is powered on and on the same network."
        case .sceneExecutionPartialFailure:
            return "Some devices may be unreachable. Review device status."
        case .containerInitializationFailed:
            return "Try restarting the app. If the problem persists, reinstall."
        default:
            return nil
        }
    }
}
