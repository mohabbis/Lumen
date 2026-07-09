import Foundation

// MARK: - IR Transport
// The seam between the app and however an IR code actually reaches a device.
// Callers pass value types only (never a SwiftData model), matching the
// SmartHomeBridge snapshot convention. Two transports conform today:
// HTTPIRTransport (POST to a user-run bridge) and BroadlinkTransport (native
// RM blaster over UDP). Only the latter can learn codes, so learning is a
// separate, optional capability.

/// Addressing for an IR target. `address` is what the user typed
/// (RemoteProfile.bridgeHostname); `mac`/`deviceType` are Broadlink-only hints
/// that avoid a discovery round-trip when already known.
struct IRHost: Sendable, Equatable {
    let address: String
    var mac: String?
    var deviceType: Int?

    init(address: String, mac: String? = nil, deviceType: Int? = nil) {
        self.address = address
        self.mac = mac
        self.deviceType = deviceType
    }
}

protocol IRTransport: Sendable {
    func send(code: String, format: IRFormat, to host: IRHost) async throws
}

/// A transport that can capture an IR code from a physical remote. Broadlink
/// conforms; HTTPIRTransport does not (a user-run bridge would need its own
/// learn endpoint, out of scope). Returns a base64-encoded Broadlink code
/// (an `IRFormat.broadlink` value).
protocol IRLearningTransport: IRTransport {
    func learn(from host: IRHost, timeout: Duration) async throws -> String
}
