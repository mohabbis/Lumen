import Foundation
import Observation
import SwiftData

#if canImport(CoreNFC)
import CoreNFC
#endif

// MARK: - NFC Service
// Reads/writes NDEF tags that carry a Lumen scene UUID (`lumen://scene/<uuid>`).
// Discovery never executes a scene — callers must route through SceneApprovalSheet.

@MainActor
@Observable
final class NFCService {

    // MARK: - Public State

    private(set) var isReaderSessionActive = false
    private(set) var lastError: (any Error)?
    private(set) var lastNFCMessage: String?

    /// Set when a tag containing a scene UUID is read. Cleared by `consumeDiscoveredSceneID()`.
    private(set) var discoveredSceneID: UUID?

    // MARK: - Dependencies

    private let sceneService: SceneService
    private let modelContext: ModelContext

    // MARK: - Session

    #if canImport(CoreNFC)
    private var readerSession: NFCNDEFReaderSession?
    private var sessionBridge: NFCSessionBridge?
    private var pendingWriteSceneID: UUID?
    #endif

    init(sceneService: SceneService, modelContext: ModelContext) {
        self.sceneService = sceneService
        self.modelContext = modelContext
    }

    // MARK: - Public API

    /// Begin an interactive read session. Does nothing (sets `lastError`) when NFC is unavailable.
    func beginScanning() {
        #if canImport(CoreNFC)
        guard NFCNDEFReaderSession.readingAvailable else {
            lastError = NFCError.notSupported
            return
        }

        pendingWriteSceneID = nil
        startSession(alert: "Hold your iPhone near an NFC tag to open a scene.")
        #else
        lastError = NFCError.notSupported
        #endif
    }

    func endScanning() {
        #if canImport(CoreNFC)
        readerSession?.invalidate()
        readerSession = nil
        sessionBridge = nil
        #endif
        isReaderSessionActive = false
    }

    /// Begin a write session that encodes `lumen://scene/<id>` onto the next writable tag.
    func writeSceneToTag(_ scene: Scene) {
        #if canImport(CoreNFC)
        guard NFCNDEFReaderSession.readingAvailable else {
            lastError = NFCError.notSupported
            return
        }

        pendingWriteSceneID = scene.id
        startSession(alert: "Hold your iPhone near an NFC tag to write “\(scene.name)”.")
        #else
        lastError = NFCError.notSupported
        #endif
    }

    /// Returns and clears the most recently discovered scene ID (for approval routing).
    func consumeDiscoveredSceneID() -> UUID? {
        let id = discoveredSceneID
        discoveredSceneID = nil
        return id
    }

    // MARK: - Session Helpers

    #if canImport(CoreNFC)
    private func startSession(alert: String) {
        let bridge = NFCSessionBridge(owner: self)
        sessionBridge = bridge

        let session = NFCNDEFReaderSession(
            delegate: bridge,
            queue: nil,
            invalidateAfterFirstRead: true
        )
        session.alertMessage = alert
        readerSession = session
        isReaderSessionActive = true
        lastError = nil
        session.begin()
    }

    fileprivate func handleSessionInvalidated(error: Error) {
        if let readerError = error as? NFCReaderError {
            switch readerError.code {
            case .readerSessionInvalidationErrorFirstNDEFTagRead,
                 .readerSessionInvalidationErrorUserCanceled:
                isReaderSessionActive = false
                readerSession = nil
                sessionBridge = nil
                pendingWriteSceneID = nil
                return
            default:
                break
            }
        }

        lastError = error
        isReaderSessionActive = false
        readerSession = nil
        sessionBridge = nil
        pendingWriteSceneID = nil
    }

    fileprivate func handleDetectedMessages(_ messages: [NFCNDEFMessage]) {
        for message in messages {
            if let sceneID = Self.sceneID(from: message) {
                discoveredSceneID = sceneID
                lastNFCMessage = "Found scene \(sceneID.uuidString)"
                readerSession?.alertMessage = "Scene found. Confirm in Lumen to run it."
                return
            }
        }
        lastError = NFCError.unsupportedTag
    }

    fileprivate func handleDetectedTags(_ tags: [NFCNDEFTag]) {
        guard let tag = tags.first, let session = readerSession else { return }
        let writeID = pendingWriteSceneID

        session.connect(to: tag) { [weak self] connectError in
            guard let self else { return }
            if let connectError {
                Task { @MainActor in
                    self.lastError = connectError
                    session.invalidate(errorMessage: "Connection failed. Please try again.")
                }
                return
            }

            if let writeID {
                self.performWrite(sceneID: writeID, to: tag, session: session)
            } else {
                self.performRead(from: tag, session: session)
            }
        }
    }

    private func performRead(from tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        tag.readNDEF { [weak self] message, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.lastError = error
                    session.invalidate(errorMessage: "Could not read this tag.")
                    return
                }
                if let message, let sceneID = Self.sceneID(from: message) {
                    self.discoveredSceneID = sceneID
                    self.lastNFCMessage = "Found scene \(sceneID.uuidString)"
                    session.alertMessage = "Scene found. Confirm in Lumen to run it."
                    session.invalidate()
                } else {
                    self.lastError = NFCError.unsupportedTag
                    session.invalidate(errorMessage: "No Lumen scene on this tag.")
                }
            }
        }
    }

    private func performWrite(sceneID: UUID, to tag: NFCNDEFTag, session: NFCNDEFReaderSession) {
        guard let message = Self.makeNDEFMessage(sceneID: sceneID) else {
            Task { @MainActor in
                self.lastError = NFCError.unsupportedTag
                session.invalidate(errorMessage: "Could not encode scene.")
            }
            return
        }

        tag.queryNDEFStatus { [weak self] status, _, error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    self.lastError = error
                    session.invalidate(errorMessage: "Unable to validate tag.")
                    return
                }

                switch status {
                case .notSupported:
                    self.lastError = NFCError.unsupportedTag
                    session.invalidate(errorMessage: "Tag is not NDEF-compatible.")
                case .readOnly:
                    self.lastError = NFCError.readOnlyTag
                    session.invalidate(errorMessage: "Tag is read-only.")
                case .readWrite:
                    tag.writeNDEF(message) { writeError in
                        Task { @MainActor in
                            if let writeError {
                                self.lastError = writeError
                                session.invalidate(errorMessage: "Write failed. Please try again.")
                            } else {
                                self.lastNFCMessage = "Wrote scene \(sceneID.uuidString)"
                                self.pendingWriteSceneID = nil
                                session.alertMessage = "Scene written."
                                session.invalidate()
                            }
                        }
                    }
                @unknown default:
                    self.lastError = NFCError.unknownStatus
                    session.invalidate(errorMessage: "Unable to validate tag.")
                }
            }
        }
    }

    private static func sceneID(from message: NFCNDEFMessage) -> UUID? {
        for record in message.records {
            if let url = record.wellKnownTypeURIPayload(),
               let id = sceneID(fromURL: url) {
                return id
            }
            if let text = String(data: record.payload, encoding: .utf8) {
                if let id = UUID(uuidString: text.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    return id
                }
                if let url = URL(string: text), let id = sceneID(fromURL: url) {
                    return id
                }
            }
        }
        return nil
    }

    private static func sceneID(fromURL url: URL) -> UUID? {
        guard url.scheme == "lumen", url.host == "scene" else { return nil }
        let candidate = url.pathComponents.last ?? url.lastPathComponent
        return UUID(uuidString: candidate)
    }

    private static func makeNDEFMessage(sceneID: UUID) -> NFCNDEFMessage? {
        let urlString = "lumen://scene/\(sceneID.uuidString)"
        guard let payload = NFCNDEFPayload.wellKnownTypeURIPayload(string: urlString) else {
            return nil
        }
        return NFCNDEFMessage(records: [payload])
    }
    #endif
}

// MARK: - CoreNFC Delegate Bridge

#if canImport(CoreNFC)
private final class NFCSessionBridge: NSObject, NFCNDEFReaderSessionDelegate {
    weak var owner: NFCService?

    init(owner: NFCService) {
        self.owner = owner
    }

    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        Task { @MainActor in
            owner?.handleSessionInvalidated(error: error)
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        Task { @MainActor in
            owner?.handleDetectedMessages(messages)
        }
    }

    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        Task { @MainActor in
            owner?.handleDetectedTags(tags)
        }
    }
}
#endif

// MARK: - Errors

enum NFCError: LocalizedError {
    case notSupported
    case unsupportedTag
    case readOnlyTag
    case unknownStatus

    var errorDescription: String? {
        switch self {
        case .notSupported:
            return "NFC is not supported on this device."
        case .unsupportedTag:
            return "The scanned tag is not a Lumen scene tag."
        case .readOnlyTag:
            return "The scanned tag is read-only and cannot be written to."
        case .unknownStatus:
            return "Unable to validate the NFC tag."
        }
    }
}
