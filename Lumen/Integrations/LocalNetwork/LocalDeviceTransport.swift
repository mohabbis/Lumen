import Foundation

// MARK: - Local Device Transport
// The seam between the app and however a local-network device is actually
// controlled over the LAN. This is the "Homebridge move": it reaches devices
// that never made it into Apple Home (Shelly, and later Tasmota / ESPHome /
// generic REST), keeping Lumen local-first — no cloud, no account.
//
// Only value types cross this boundary (never a SwiftData model), matching the
// SmartHomeBridge snapshot convention and the IRTransport seam. One transport
// conforms today: ShellyGen2Transport (Shelly Gen2 RPC over local HTTP).

/// Addressing for a local device. `address` is what the user typed — a bare IP
/// or host ("192.168.1.50", "shelly.local"), "host:port", or a full http URL.
struct LocalHost: Sendable, Equatable {
    let address: String
    init(address: String) { self.address = address }
}

/// A protocol-agnostic view of *what kind of control point* a target is, so the
/// seam stays independent of any one vendor's component naming. `relay` is a
/// plain on/off point; `light` additionally accepts brightness. Each concrete
/// transport maps these onto its own components (Shelly: `relay`→`Switch`,
/// `light`→`Light`).
enum LocalComponent: String, Sendable, Equatable, Codable {
    case relay
    case light
}

/// Addresses one controllable point on a device: a host, which component it is,
/// and which channel/index (multi-relay devices expose several).
struct LocalTarget: Sendable, Equatable {
    let host: LocalHost
    let component: LocalComponent
    let channel: Int

    init(host: LocalHost, component: LocalComponent, channel: Int = 0) {
        self.host = host
        self.component = component
        self.channel = channel
    }
}

/// A control command to apply to a local target.
enum LocalDeviceCommand: Sendable, Equatable {
    case power(Bool)
    /// Normalised 0.0…1.0. Transports scale to whatever the device expects.
    case brightness(Double)
}

/// A read-back snapshot of a target's controllable state. Fields are optional so
/// a relay (no brightness) and a light report through the same value type.
struct LocalDeviceReading: Sendable, Equatable {
    var isOn: Bool?
    var brightness: Double?

    init(isOn: Bool? = nil, brightness: Double? = nil) {
        self.isOn = isOn
        self.brightness = brightness
    }
}

protocol LocalDeviceTransport: Sendable {
    /// Apply a single command to a target. Throws on a bad address or transport failure.
    func apply(_ command: LocalDeviceCommand, to target: LocalTarget) async throws

    /// Read the current state of a target.
    func read(from target: LocalTarget) async throws -> LocalDeviceReading
}
