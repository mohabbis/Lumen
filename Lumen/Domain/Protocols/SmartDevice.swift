import Foundation

// MARK: - Type Aliases

typealias DeviceID = UUID

// MARK: - Device Reachability

enum DeviceReachability: Equatable, Sendable {
    case reachable
    case unreachable
    case unknown
    case settingUp

    var systemImage: String {
        switch self {
        case .reachable:   return "checkmark.circle.fill"
        case .unreachable: return "exclamationmark.wifi"
        case .unknown:     return "circle.dashed"
        case .settingUp:   return "gearshape"
        }
    }

    var isOperational: Bool { self == .reachable }
}

// MARK: - Smart Device Protocol

protocol SmartDevice: Identifiable, Sendable {
    var id: DeviceID { get }
    var displayName: String { get }
    var roomName: String? { get }
    var reachability: DeviceReachability { get }
    var bridgeID: BridgeID { get }
    var category: DeviceCategory { get }
    var capabilities: [any DeviceCapability] { get }
}

// MARK: - Default Implementations

extension SmartDevice {

    func capability<C: DeviceCapability>(of type: C.Type) -> C? {
        capabilities.first { $0 is C } as? C
    }

    func supports(_ capabilityID: CapabilityID) -> Bool {
        capabilities.contains { $0.capabilityID == capabilityID }
    }

    var isControllable: Bool {
        capabilities.contains { !$0.isReadOnly }
    }
}

// MARK: - Device Category
// Used for UI grouping only — never for type-checking device behaviour.

enum DeviceCategory: String, Sendable, CaseIterable, Codable {
    case lighting       = "Lighting"
    case climate        = "Climate"
    case security       = "Security"
    case sensors        = "Sensors"
    case entertainment  = "Entertainment"
    case appliances     = "Appliances"
    case other          = "Other"

    var systemImage: String {
        switch self {
        case .lighting:      return "lightbulb.fill"
        case .climate:       return "thermometer"
        case .security:      return "lock.shield.fill"
        case .sensors:       return "sensor.tag.radiowaves.forward.fill"
        case .entertainment: return "tv"
        case .appliances:    return "washer.fill"
        case .other:         return "circle.grid.2x2.fill"
        }
    }
}

// MARK: - State Change Event (bridge → state store)

struct DeviceStateChange: Sendable {
    let deviceID: DeviceID
    let capabilityID: CapabilityID
    let timestamp: Date

    init(deviceID: DeviceID, capabilityID: CapabilityID) {
        self.deviceID = deviceID
        self.capabilityID = capabilityID
        self.timestamp = Date()
    }
}
