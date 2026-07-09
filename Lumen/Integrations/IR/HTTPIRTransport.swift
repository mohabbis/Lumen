import Foundation

// MARK: - HTTP IR Transport
// Sends an IR code to a user-run IR bridge over the local network by POSTing
// JSON to <bridge>/send. Works with a small DIY / ESP blaster or a Home
// Assistant style REST shim. The request-building and address-parsing are pure
// static helpers so they can be unit-tested without any networking. A native
// Broadlink LAN transport can replace this behind IRTransport later.

struct HTTPIRTransport: IRTransport {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // Resolves the host address to a URL and POSTs the code. Throws
    // AppError.invalidBridgeHostname on a bad address; otherwise raw transport
    // errors (URLSession failures, or a bad HTTP status). RemoteService maps
    // non-AppError throws to AppError.irSendFailed.
    func send(code: String, format: IRFormat, to host: IRHost) async throws {
        let endpoint = try Self.normalizedEndpoint(from: host.address)
        let request = Self.makeRequest(endpoint: endpoint, code: code, format: format)
        let (_, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Pure Helpers (unit-tested)

    /// Builds the POST request for an IR bridge. Pure and side-effect free.
    /// Convention: POST `<endpoint>/send` with `{ "format": ..., "code": ... }`.
    static func makeRequest(endpoint: URL, code: String, format: IRFormat) -> URLRequest {
        var request = URLRequest(url: endpoint.appending(path: "send"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: ["format": format.rawValue, "code": code]
        )
        return request
    }

    /// Normalizes a user-entered bridge address into a base URL. Accepts a bare
    /// IP or host ("192.168.1.50", "blaster.local"), "host:port", or a full
    /// http(s) URL. Pure and side-effect free.
    static func normalizedEndpoint(from hostname: String) throws -> URL {
        let trimmed = hostname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.remoteBridgeNotConfigured }

        let withScheme = trimmed.contains("://") ? trimmed : "http://\(trimmed)"
        guard let url = URL(string: withScheme),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else {
            throw AppError.invalidBridgeHostname(hostname)
        }
        return url
    }
}
