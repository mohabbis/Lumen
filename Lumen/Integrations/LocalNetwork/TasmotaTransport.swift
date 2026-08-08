import Foundation

// MARK: - Tasmota Transport
// Controls Tasmota devices over the local network via their HTTP command API —
// no cloud, no account. Tasmota runs on thousands of ESP8266/ESP32 devices
// (Sonoff, smart plugs, bulbs, strips), so this one transport unlocks a huge
// slice of affordable hardware Apple Home never sees.
//
// Everything is a single `cmnd` sent to `/cm`. URL-building and JSON-parsing are
// pure static helpers so they unit-test without networking, exactly like
// ShellyGen2Transport. Channels are 1-based in Tasmota (Power1, Power2, …); we
// take a 0-based `channel` like the rest of the seam and add one.
//
//   Relay on:   GET /cm?cmnd=Power1%20ON        → {"POWER1":"ON"}
//   Dimmer:     GET /cm?cmnd=Dimmer%2040        → {"Dimmer":40}
//   Read all:   GET /cm?cmnd=State              → {"POWER1":"ON","Dimmer":40,…}

struct TasmotaTransport: LocalDeviceTransport {

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
        let url = Self.statusURL(base: base)
        let (data, response) = try await session.data(from: url)
        try Self.validate(response)
        return Self.parseReading(data: data, channel: target.channel)
    }

    // MARK: - Pure Helpers (unit-tested)

    /// The Tasmota power command name for a 0-based channel: `Power1`, `Power2`, …
    static func powerCommandName(channel: Int) -> String {
        "Power\(max(0, channel) + 1)"
    }

    /// Builds the `/cm` URL that applies `command` to `target`. Returns nil when the
    /// command is not expressible on the target's component (brightness on a relay).
    static func setURL(base: URL, target: LocalTarget, command: LocalDeviceCommand) -> URL? {
        switch command {
        case .power(let on):
            return commandURL(base: base, cmnd: "\(powerCommandName(channel: target.channel)) \(on ? "ON" : "OFF")")
        case .brightness(let value):
            guard target.component == .light else { return nil }
            let percent = Int((value.clamped(to: 0.0...1.0) * 100).rounded())
            return commandURL(base: base, cmnd: "Dimmer \(percent)")
        }
    }

    /// Builds the `/cm` URL that reads the device's full state.
    static func statusURL(base: URL) -> URL {
        commandURL(base: base, cmnd: "State")!
    }

    /// Parses a Tasmota JSON body into a reading for `channel` (0-based). Reads the
    /// `POWER<n>` key, falling back to a bare `POWER` for single-relay devices;
    /// `Dimmer` (0–100) maps to 0.0–1.0. Unknown fields are ignored.
    static func parseReading(data: Data, channel: Int) -> LocalDeviceReading {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return LocalDeviceReading()
        }

        var isOn: Bool?
        if let value = powerValue(object["POWER\(max(0, channel) + 1)"]) ?? powerValue(object["POWER"]) {
            isOn = value
        }

        var brightness: Double?
        if let raw = object["Dimmer"] as? NSNumber {
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

    /// Tasmota reports power as the string "ON"/"OFF"; some setups report a bool.
    private static func powerValue(_ raw: Any?) -> Bool? {
        if let string = raw as? String {
            switch string.uppercased() {
            case "ON", "1", "TRUE": return true
            case "OFF", "0", "FALSE": return false
            default: return nil
            }
        }
        if let bool = raw as? Bool { return bool }
        return nil
    }

    private static func commandURL(base: URL, cmnd: String) -> URL? {
        let endpoint = base.appending(path: "cm")
        guard var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return nil
        }
        components.queryItems = [URLQueryItem(name: "cmnd", value: cmnd)]
        return components.url
    }

    private static func validate(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw URLError(.badServerResponse)
        }
    }
}
