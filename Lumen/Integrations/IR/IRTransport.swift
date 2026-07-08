import Foundation

// MARK: - IR Transport
// The seam between the app and however an IR code actually reaches a device.
// Callers pass value types only (never a SwiftData model), matching the
// SmartHomeBridge snapshot convention. Today only HTTPIRTransport exists
// (POST to a user-run IR bridge); a native Broadlink LAN transport can conform
// to this later without touching any caller.

protocol IRTransport: Sendable {
    func send(code: String, format: IRFormat, to endpoint: URL) async throws
}
