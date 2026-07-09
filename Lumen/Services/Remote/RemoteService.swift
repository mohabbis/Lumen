import Foundation
import Observation

// MARK: - Remote Service
// Owns sending and learning IR commands. Standalone (not a SmartHomeBridge):
// IR is fire-and-forget with no state stream or reachability. Routes to the
// transport a RemoteProfile selects and hands it value types only.

@MainActor
@Observable
final class RemoteService {

    private let httpTransport: any IRTransport
    private let broadlinkTransport: any IRLearningTransport

    init(
        httpTransport: any IRTransport = HTTPIRTransport(),
        broadlinkTransport: any IRLearningTransport = BroadlinkTransport()
    ) {
        self.httpTransport = httpTransport
        self.broadlinkTransport = broadlinkTransport
    }

    /// Sends a single IR command using the remote's selected transport and
    /// configured address. Throws `AppError.remoteBridgeNotConfigured` when the
    /// remote has no address; other transport failures surface as
    /// `AppError.irSendFailed` (AppErrors from the transport pass through).
    func send(_ command: IRCommand, using profile: RemoteProfile) async throws {
        let host = try makeHost(for: profile)
        do {
            try await transport(for: profile.transportKind)
                .send(code: command.irCode, format: command.irFormat, to: host)
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.irSendFailed(underlying: error)
        }
    }

    /// Captures an IR code from a physical remote via the blaster. Throws
    /// `AppError.learningNotSupported` when the selected transport can't learn.
    func learn(using profile: RemoteProfile, timeout: Duration = .seconds(30)) async throws -> String {
        let host = try makeHost(for: profile)
        guard let learner = transport(for: profile.transportKind) as? IRLearningTransport else {
            throw AppError.learningNotSupported
        }
        do {
            return try await learner.learn(from: host, timeout: timeout)
        } catch let appError as AppError {
            throw appError
        } catch {
            throw AppError.irSendFailed(underlying: error)
        }
    }

    // MARK: - Private

    private func transport(for kind: RemoteTransportKind) -> any IRTransport {
        switch kind {
        case .http:      return httpTransport
        case .broadlink: return broadlinkTransport
        }
    }

    private func makeHost(for profile: RemoteProfile) throws -> IRHost {
        guard let address = profile.bridgeHostname,
              !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AppError.remoteBridgeNotConfigured
        }
        return IRHost(address: address, mac: profile.broadlinkMAC, deviceType: profile.broadlinkDeviceType)
    }
}
