import Foundation

// MARK: - Shelly Gen2 Transport
// Controls Shelly Gen2 devices over the local network via their HTTP RPC API —
// no cloud, no account. The URL-building and JSON-parsing are pure static
// helpers so they can be unit-tested without any networking, exactly like
// HTTPIRTransport. A device's RPC lives at `http://<host>/rpc/<Method>`; we use
// the GET form with query parameters.
//
//   Relay on:      GET /rpc/Switch.Set?id=0&on=true
//   Light dim:     GET /rpc/Light.Set?id=0&brightness=40
//   Read a relay:  GET /rpc/Switch.GetStatus?id=0   → { "output": true, … }
//   Read a light:  GET /rpc/Light.GetStatus?id=0    → { "output": true, "brightness": 40, … }

struct ShellyGen2Transport: LocalDeviceTransport {

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func apply(_ command: LocalDeviceCommand, to target: LocalTarget) async throws {
        let base = try Self.normalizedBaseURL(from: target.host.address)
        guard let url = Self.setURL(base: base, target: target, command: command) else {
            throw URLError(.unsupportedURL)   // command not expressible on this component
        }
        let (_, response) = try await session.data(from: url)
        try Self.validate(response)
    }

    func read(from target: LocalTarget) async throws -> LocalDeviceReading {
        let base = try Self.normalizedBaseURL(from: target.host.address)
        let url = Self.statusURL(base: base, target: target)
        let (data, response) = try await session.data(from: url)
        try Self.validate(response)
        return Self.parseReading(data: data)
    }

    // MARK: - Pure Helpers (unit-tested)

    /// The Shelly RPC component name for a protocol-agnostic component.
    static func rpcComponent(for component: LocalComponent) -> String {
        switch component {
        case .relay: return "Switch"
        case .light: return "Light"
        }
    }

    /// Builds the RPC URL that applies `command` to `target`. Returns nil when the
    /// command is not expressible on the target's component (e.g. brightness on a
    /// plain relay) — callers surface that as an invalid request.
    static func setURL(base: URL, target: LocalTarget, command: LocalDeviceCommand) -> URL? {
        var query: [URLQueryItem] = [URLQueryItem(name: "id", value: String(target.channel))]

        switch command {
        case .power(let on):
            query.append(URLQueryItem(name: "on", value: on ? "true" : "false"))
        case .brightness(let value):
            guard target.component == .light else { return nil }
            let percent = Int((value.clamped(to: 0.0...1.0) * 100).rounded())
            query.append(URLQueryItem(name: "brightness", value: String(percent)))
        }

        return rpcURL(base: base, method: "\(rpcComponent(for: target.component)).Set", query: query)
    }

    /// Builds the RPC URL that reads `target`'s status.
    static func statusURL(base: URL, target: LocalTarget) -> URL {
        rpcURL(
            base: base,
            method: "\(rpcComponent(for: target.component)).GetStatus",
            query: [URLQueryItem(name: "id", value: String(target.channel))]
        )!
    }

    /// Parses a Shelly `*.GetStatus` JSON body into a reading. Unknown fields are
    /// ignored; `output` maps to power, `brightness` (0–100) to 0.0–1.0.
    static func parseReading(data: Data) -> LocalDeviceReading {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return LocalDeviceReading()
        }
        let isOn = object["output"] as? Bool
        var brightness: Double?
        if let raw = object["brightness"] as? NSNumber {
            brightness = (raw.doubleValue / 100.0).clamped(to: 0.0...1.0)
        }
        return LocalDeviceReading(isOn: isOn, brightness: brightness)
    }

    /// Normalises a user-entered address into a base URL. Accepts a bare IP or
    /// host, "host:port", or a full http(s) URL. Pure and side-effect free.
    static func normalizedBaseURL(from address: String) throws -> URL {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AppError.invalidBridgeHostname(address) }

        let withScheme = trimmed.contains("://") ? trimmed : "http://\(trimmed)"
        guard let url = URL(string: withScheme),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else {
            throw AppError.invalidBridgeHostname(address)
        }
        return url
    }

    // MARK: - Private

    private static func rpcURL(base: URL, method: String, query: [URLQueryItem]) -> URL? {
        let endpoint = base.appending(path: "rpc").appending(path: method)
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = query
        return components.url
    }

    private static func validate(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
    }
}
