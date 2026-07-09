import Foundation
import Observation
import SwiftData

// MARK: - Remote View Model

@MainActor
@Observable
final class RemoteViewModel {

    private let modelContext: ModelContext
    private let remoteService: RemoteService

    var isShowingAddRemote = false
    var isShowingAddCommand = false
    var isLearning = false
    var error: (any Error)?

    init(modelContext: ModelContext, remoteService: RemoteService = RemoteService()) {
        self.modelContext = modelContext
        self.remoteService = remoteService
    }

    // MARK: - Remote CRUD

    func createRemote(name: String, brand: String? = nil, iconName: String = "remote") {
        let remote = RemoteProfile(name: name, deviceBrand: brand, iconName: iconName)
        modelContext.insert(remote)
        do {
            try modelContext.save()
            isShowingAddRemote = false
        } catch {
            self.error = error
        }
    }

    func deleteRemote(_ remote: RemoteProfile) {
        modelContext.delete(remote)
        do { try modelContext.save() }
        catch { self.error = error }
    }

    func setBridgeHostname(_ hostname: String?, on remote: RemoteProfile) {
        let trimmed = hostname?.trimmingCharacters(in: .whitespacesAndNewlines)
        remote.bridgeHostname = (trimmed?.isEmpty ?? true) ? nil : trimmed
        remote.updatedAt = Date()
        do { try modelContext.save() }
        catch { self.error = error }
    }

    func setTransportKind(_ kind: RemoteTransportKind, on remote: RemoteProfile) {
        remote.transportKind = kind
        remote.updatedAt = Date()
        do { try modelContext.save() }
        catch { self.error = error }
    }

    // MARK: - Command CRUD

    func addCommand(to remote: RemoteProfile, name: String, code: String, format: IRFormat) {
        let command = IRCommand(
            name: name,
            irCode: code,
            irFormat: format,
            sortOrder: remote.commands.count
        )
        command.remote = remote
        modelContext.insert(command)
        remote.updatedAt = Date()
        do {
            try modelContext.save()
            isShowingAddCommand = false
        } catch {
            self.error = error
        }
    }

    func deleteCommand(_ command: IRCommand) {
        modelContext.delete(command)
        do { try modelContext.save() }
        catch { self.error = error }
    }

    // MARK: - Sending
    // Async and non-throwing: failures are written to `error` and surfaced by a
    // visible alert, matching HomeViewModel.executeScene. No `try?` swallows.

    func send(_ command: IRCommand, from remote: RemoteProfile) async {
        do {
            try await remoteService.send(command, using: remote)
        } catch {
            self.error = error
        }
    }

    /// Captures a code from a physical remote via the blaster. Returns the
    /// base64 Broadlink code on success, or nil (with `error` set) on failure.
    func learn(from remote: RemoteProfile) async -> String? {
        isLearning = true
        defer { isLearning = false }
        do {
            return try await remoteService.learn(using: remote)
        } catch {
            self.error = error
            return nil
        }
    }
}
