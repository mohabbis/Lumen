import Foundation
import Observation

// MARK: - Remote Service
// Owns sending IR commands. Standalone (not a SmartHomeBridge): IR is
// fire-and-forget with no state stream or reachability, so it does not belong
// in the device/scene pipeline. Resolves a RemoteProfile's bridge address and
// hands the code's value types to an injectable IRTransport.

@MainActor
@Observable
final class RemoteService {

    private let transport: any IRTransport

    init(transport: any IRTransport = HTTPIRTransport()) {
        self.transport = transport
    }

    /// Sends a single IR command using its remote's configured bridge address.
    /// Throws `AppError.remoteBridgeNotConfigured` when the remote has no
    /// address, `AppError.invalidBridgeHostname` when it cannot be parsed, and
    /// `AppError.irSendFailed` when the transport fails.
    func send(_ command: IRCommand, using profile: RemoteProfile) async throws {
        guard let hostname = profile.bridgeHostname,
              !hostname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.remoteBridgeNotConfigured
        }
        let endpoint = try HTTPIRTransport.normalizedEndpoint(from: hostname)
        do {
            try await transport.send(code: command.irCode, format: command.irFormat, to: endpoint)
        } catch {
            throw AppError.irSendFailed(underlying: error)
        }
    }
}
