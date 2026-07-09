import Foundation

// MARK: - Broadlink Transport
// Native RM-blaster transport over UDP. Drives the pure BroadlinkProtocol codec
// through an injectable UDPChannel (real NWUDPChannel in the app, a fake in
// tests). Holds a per-device session (id + key) cache so we authenticate once.
// IR is fire-and-forget, so this is standalone, not a SmartHomeBridge.

actor BroadlinkTransport: IRLearningTransport {

    private let channel: any UDPChannel
    private let port: UInt16
    private let exchangeTimeout: Duration
    private let pollInterval: Duration
    private var counter: UInt16 = 0
    private var sessions: [String: Session] = [:]   // keyed by MAC string

    private struct Session {
        let deviceID: [UInt8]
        let key: [UInt8]
    }

    init(
        channel: any UDPChannel = NWUDPChannel(),
        port: UInt16 = 80,
        exchangeTimeout: Duration = .seconds(5),
        pollInterval: Duration = .seconds(1)
    ) {
        self.channel = channel
        self.port = port
        self.exchangeTimeout = exchangeTimeout
        self.pollInterval = pollInterval
    }

    // MARK: - IRTransport

    func send(code: String, format: IRFormat, to host: IRHost) async throws {
        guard format == .broadlink else { throw AppError.unsupportedIRFormat(format) }
        guard let irData = Data(base64Encoded: code) else {
            throw AppError.irSendFailed(underlying: CodecError.badCode)
        }
        let device = try await resolve(host)
        let session = try await session(for: device, address: host.address)
        let payload = BroadlinkProtocol.sendIRPayload(code: [UInt8](irData))
        _ = try await command(payload, device: device, session: session, address: host.address)
    }

    // MARK: - IRLearningTransport

    func learn(from host: IRHost, timeout: Duration) async throws -> String {
        let device = try await resolve(host)
        let session = try await session(for: device, address: host.address)

        // Put the blaster into learning mode, then poll for a captured code.
        _ = try await command(BroadlinkProtocol.enterLearningPayload(),
                              device: device, session: session, address: host.address)

        // The device reports "still waiting" with a non-zero error code until a
        // code is captured; only error 0 carries the learned bytes.
        let deadline = ContinuousClock.now.advanced(by: timeout)
        while ContinuousClock.now < deadline {
            try await Task.sleep(for: pollInterval)
            let (error, payload) = try await rawCommand(BroadlinkProtocol.checkLearnedPayload(),
                                                        device: device, session: session, address: host.address)
            if error == 0, let code = BroadlinkProtocol.parseLearnedCode(payload: payload) {
                return Data(code).base64EncodedString()
            }
        }
        throw AppError.irLearnTimedOut
    }

    // MARK: - Steps

    /// Finds the device's MAC + type: uses the host's hints when present, else
    /// unicasts a discovery hello to the address.
    private func resolve(_ host: IRHost) async throws -> BroadlinkDevice {
        if let macString = host.mac, let mac = BroadlinkDevice.mac(from: macString), let type = host.deviceType {
            return BroadlinkDevice(mac: mac, deviceType: type)
        }
        let hello = BroadlinkProtocol.discoveryPacket(localIP: [0, 0, 0, 0], localPort: 0)
        let reply = try await exchange(hello, address: host.address)
        guard let device = BroadlinkProtocol.parseDiscovery([UInt8](reply)) else {
            throw AppError.broadlinkDeviceNotFound
        }
        return device
    }

    /// Authenticates once per device, caching the returned id + session key.
    private func session(for device: BroadlinkDevice, address: String) async throws -> Session {
        if let cached = sessions[device.macString] { return cached }

        let packet = BroadlinkProtocol.buildPacket(
            command: BroadlinkProtocol.Command.auth,
            payload: BroadlinkProtocol.authPayload(),
            mac: device.mac,
            deviceType: device.deviceType,
            counter: nextCounter(),
            deviceID: [0, 0, 0, 0],
            key: BroadlinkProtocol.defaultKey
        )
        let reply = try await exchange(packet, address: address)
        let (error, payload) = BroadlinkProtocol.parseResponse([UInt8](reply), key: BroadlinkProtocol.defaultKey)
        guard error == 0, let auth = BroadlinkProtocol.parseAuth(payload: payload) else {
            throw AppError.broadlinkDeviceNotFound
        }
        let session = Session(deviceID: auth.deviceID, key: auth.key)
        sessions[device.macString] = session
        return session
    }

    /// Sends an authenticated 0x6a command and returns the decrypted response
    /// payload, throwing on a non-zero device error code.
    @discardableResult
    private func command(_ payload: [UInt8], device: BroadlinkDevice, session: Session, address: String) async throws -> [UInt8] {
        let (error, responsePayload) = try await rawCommand(payload, device: device, session: session, address: address)
        guard error == 0 else { throw AppError.irSendFailed(underlying: CodecError.deviceError(Int(error))) }
        return responsePayload
    }

    /// Like `command` but returns the device error code instead of throwing, so
    /// the learn poll can tell "still waiting" from a real failure.
    private func rawCommand(_ payload: [UInt8], device: BroadlinkDevice, session: Session, address: String) async throws -> (error: Int16, payload: [UInt8]) {
        let packet = BroadlinkProtocol.buildPacket(
            command: BroadlinkProtocol.Command.normal,
            payload: payload,
            mac: device.mac,
            deviceType: device.deviceType,
            counter: nextCounter(),
            deviceID: session.deviceID,
            key: session.key
        )
        let reply = try await exchange(packet, address: address)
        return BroadlinkProtocol.parseResponse([UInt8](reply), key: session.key)
    }

    private func exchange(_ packet: [UInt8], address: String) async throws -> Data {
        try await channel.exchange(Data(packet), host: address, port: port, timeout: exchangeTimeout)
    }

    private func nextCounter() -> UInt16 {
        counter = counter &+ 1
        return counter
    }

    enum CodecError: Error {
        case badCode
        case deviceError(Int)
    }
}
