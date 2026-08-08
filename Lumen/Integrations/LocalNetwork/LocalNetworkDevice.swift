import Foundation

// MARK: - Local Device Configuration
// A value-type description of a local-network device the user has added. The
// bridge turns each config into a LocalNetworkDevice at discovery time. Kept
// deliberately plain (no SwiftData) so the integration layer is fully testable;
// persistence + a Settings surface to author these is the next step.

/// The vendor / local protocol a device speaks. Drives which transport
/// `LocalTransportFactory` hands the bridge. Vendor-neutral seam below stays the
/// same regardless of which one a device uses.
enum LocalVendor: String, Sendable, Equatable, Codable, CaseIterable {
    case shelly     // Shelly Gen2 RPC over HTTP
    case tasmota    // Tasmota `/cm?cmnd=` command API
    case esphome    // ESPHome web_server REST API

    var displayName: String {
        switch self {
        case .shelly: return "Shelly"
        case .tasmota: return "Tasmota"
        case .esphome: return "ESPHome"
        }
    }
}

/// The concrete kind of local device. Drives the vendor/transport, the component
/// the transport talks to, and the capability set the UI renders.
enum LocalDeviceKind: String, Sendable, Equatable, Codable, CaseIterable {
    case shellySwitch    // Shelly Gen2 Switch — on/off
    case shellyDimmer    // Shelly Gen2 Light — on/off + brightness
    case tasmotaSwitch   // Tasmota relay/plug — on/off
    case tasmotaDimmer   // Tasmota dimmer/bulb — on/off + brightness
    case esphomeSwitch   // ESPHome switch entity — on/off
    case esphomeLight    // ESPHome light entity — on/off + brightness

    var vendor: LocalVendor {
        switch self {
        case .shellySwitch, .shellyDimmer: return .shelly
        case .tasmotaSwitch, .tasmotaDimmer: return .tasmota
        case .esphomeSwitch, .esphomeLight: return .esphome
        }
    }

    var component: LocalComponent {
        switch self {
        case .shellySwitch, .tasmotaSwitch, .esphomeSwitch: return .relay
        case .shellyDimmer, .tasmotaDimmer, .esphomeLight: return .light
        }
    }

    /// Whether this kind exposes a brightness capability (its component is a light).
    var supportsBrightness: Bool { component == .light }

    /// Whether authoring this kind needs a string entity name rather than a
    /// numeric channel (ESPHome addresses entities by `object_id`).
    var usesEntityID: Bool { vendor == .esphome }

    var displayName: String {
        switch self {
        case .shellySwitch: return "Shelly Switch"
        case .shellyDimmer: return "Shelly Dimmer"
        case .tasmotaSwitch: return "Tasmota Switch"
        case .tasmotaDimmer: return "Tasmota Dimmer"
        case .esphomeSwitch: return "ESPHome Switch"
        case .esphomeLight: return "ESPHome Light"
        }
    }
}

struct LocalDeviceConfig: Sendable, Equatable, Identifiable {
    let id: DeviceID
    var displayName: String
    var roomName: String?
    var host: LocalHost
    var kind: LocalDeviceKind
    var channel: Int
    /// Entity name for vendors that address by name (ESPHome). Nil for numeric-
    /// indexed vendors, which use `channel`.
    var entityID: String?
    var category: DeviceCategory

    init(
        id: DeviceID = UUID(),
        displayName: String,
        roomName: String? = nil,
        host: LocalHost,
        kind: LocalDeviceKind,
        channel: Int = 0,
        entityID: String? = nil,
        category: DeviceCategory = .lighting
    ) {
        self.id = id
        self.displayName = displayName
        self.roomName = roomName
        self.host = host
        self.kind = kind
        self.channel = channel
        self.entityID = entityID
        self.category = category
    }

    var target: LocalTarget {
        LocalTarget(host: host, component: kind.component, channel: channel, entityID: entityID)
    }
}

// MARK: - Local Network Device
// Wraps a LocalDeviceConfig as a SmartDevice. The transport never escapes into
// the rest of the app — like HomeKitDevice keeps HMAccessory private.

struct LocalNetworkDevice: SmartDevice {

    let id: DeviceID
    let displayName: String
    let roomName: String?
    let reachability: DeviceReachability
    let bridgeID: BridgeID = .localNetwork
    let category: DeviceCategory
    let capabilities: [any DeviceCapability]

    private let config: LocalDeviceConfig
    private let transport: any LocalDeviceTransport

    init(config: LocalDeviceConfig, transport: any LocalDeviceTransport, reachability: DeviceReachability = .unknown) {
        self.id = config.id
        self.displayName = config.displayName
        self.roomName = config.roomName
        self.reachability = reachability
        self.category = config.category
        self.config = config
        self.transport = transport
        self.capabilities = Self.buildCapabilities(config: config, transport: transport)
    }

    // MARK: - Action Execution (called by LocalNetworkBridge)

    func execute(_ action: SceneActionSnapshot) async throws {
        switch action.capabilityID {
        case .onOff:
            guard case .bool(let on) = action.payload else { return }
            try await transport.apply(.power(on), to: config.target)

        case .brightness:
            guard case .double(let level) = action.payload else { return }
            try await transport.apply(.brightness(level), to: config.target)

        default:
            throw AppError.capabilityNotSupported(action.capabilityID, deviceID: id)
        }
    }

    // MARK: - Capability Discovery

    private static func buildCapabilities(
        config: LocalDeviceConfig,
        transport: any LocalDeviceTransport
    ) -> [any DeviceCapability] {
        var caps: [any DeviceCapability] = [
            LocalNetworkOnOffCapability(target: config.target, transport: transport)
        ]
        if config.kind.supportsBrightness {
            caps.append(LocalNetworkBrightnessCapability(target: config.target, transport: transport))
        }
        return caps
    }
}

// MARK: - Capabilities
// Each capability holds the (Sendable) transport plus its target and reads/writes
// state on demand — the local-HTTP analogue of the HomeKit capability structs.

struct LocalNetworkOnOffCapability: OnOffCapability {
    let capabilityID: CapabilityID = .onOff
    let displayName = "Power"
    let isReadOnly = false

    let target: LocalTarget
    let transport: any LocalDeviceTransport

    var isOn: Bool {
        get async {
            (try? await transport.read(from: target).isOn) ?? false
        }
    }

    func setPower(_ on: Bool) async throws {
        try await transport.apply(.power(on), to: target)
    }

    func toggle() async throws {
        try await setPower(!(await isOn))
    }
}

struct LocalNetworkBrightnessCapability: BrightnessCapability {
    let capabilityID: CapabilityID = .brightness
    let displayName = "Brightness"
    let isReadOnly = false
    let brightnessRange: ClosedRange<Double> = 0.0...1.0

    let target: LocalTarget
    let transport: any LocalDeviceTransport

    var brightness: Double {
        get async {
            (try? await transport.read(from: target).brightness) ?? 0
        }
    }

    func setBrightness(_ value: Double) async throws {
        try await transport.apply(.brightness(value.clamped(to: 0.0...1.0)), to: target)
    }
}

extension BridgeID {
    static let localNetwork = BridgeID("localNetwork")
}
