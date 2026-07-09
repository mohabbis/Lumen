import Foundation
import Network

// MARK: - UDP Channel
// A minimal request/response UDP seam so BroadlinkTransport can be tested
// against a fake channel. The only real implementation, NWUDPChannel, wraps
// Network.framework and is the sole piece that must be verified on a device.

protocol UDPChannel: Sendable {
    /// Sends one datagram and waits for the first reply, or throws on timeout.
    func exchange(_ data: Data, host: String, port: UInt16, timeout: Duration) async throws -> Data
}

// MARK: - NWConnection Implementation

struct NWUDPChannel: UDPChannel {

    func exchange(_ data: Data, host: String, port: UInt16, timeout: Duration) async throws -> Data {
        try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask { try await Self.roundTrip(data, host: host, port: port) }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw URLError(.timedOut)
            }
            guard let result = try await group.next() else { throw URLError(.timedOut) }
            group.cancelAll()
            return result
        }
    }

    private static func roundTrip(_ data: Data, host: String, port: UInt16) async throws -> Data {
        guard let nwPort = NWEndpoint.Port(rawValue: port) else { throw URLError(.badURL) }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .udp)
        let queue = DispatchQueue(label: "com.muharafiq.lumen.udp")

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                let box = ContinuationBox(continuation)

                connection.stateUpdateHandler = { state in
                    switch state {
                    case .ready:
                        connection.send(content: data, completion: .contentProcessed { error in
                            if let error {
                                box.resume(throwing: error)
                                connection.cancel()
                            }
                        })
                        connection.receiveMessage { content, _, _, error in
                            if let content, !content.isEmpty {
                                box.resume(returning: content)
                            } else {
                                box.resume(throwing: error ?? URLError(.badServerResponse))
                            }
                            connection.cancel()
                        }
                    case .failed(let error):
                        box.resume(throwing: error)
                        connection.cancel()
                    case .cancelled:
                        box.resume(throwing: CancellationError())
                    default:
                        break
                    }
                }
                connection.start(queue: queue)
            }
        } onCancel: {
            connection.cancel()
        }
    }
}

// Resume-once guard. Only touched from NWConnection callbacks serialized on a
// single dispatch queue, so a plain flag is safe.
private final class ContinuationBox: @unchecked Sendable {
    private var continuation: CheckedContinuation<Data, Error>?

    init(_ continuation: CheckedContinuation<Data, Error>) {
        self.continuation = continuation
    }

    func resume(returning value: Data) {
        continuation?.resume(returning: value)
        continuation = nil
    }

    func resume(throwing error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
