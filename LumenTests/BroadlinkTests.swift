import XCTest
@testable import Lumen

final class BroadlinkTests: XCTestCase {

    // MARK: - Checksum

    func testChecksumBaseline() {
        XCTAssertEqual(BroadlinkProtocol.checksum([]), 0xBEAF)
        XCTAssertEqual(BroadlinkProtocol.checksum([0x01, 0x02]), 0xBEB2)
    }

    // MARK: - AES-128-CBC

    func testAESRoundTrip() {
        let block = Array("Broadlink AES!!!".utf8)   // exactly 16 bytes
        XCTAssertEqual(block.count, 16)
        let encrypted = BroadlinkProtocol.aesEncrypt(block, key: BroadlinkProtocol.defaultKey)
        XCTAssertEqual(encrypted.count, 16)
        XCTAssertNotEqual(encrypted, block)
        let decrypted = BroadlinkProtocol.aesDecrypt(encrypted, key: BroadlinkProtocol.defaultKey)
        XCTAssertEqual(decrypted, block)
    }

    // MARK: - Packet framing

    func testBuildPacketStructure() {
        let payload: [UInt8] = [0x02, 0x00, 0x00, 0x00, 0xAB]   // 5 bytes -> padded to 16
        let mac: [UInt8] = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66]
        let deviceID: [UInt8] = [0xDE, 0xAD, 0xBE, 0xEF]

        let packet = BroadlinkProtocol.buildPacket(
            command: 0x6a, payload: payload, mac: mac, deviceType: 0x5f36,
            counter: 0x0102, deviceID: deviceID, key: BroadlinkProtocol.defaultKey
        )

        XCTAssertEqual(Array(packet[0..<8]), BroadlinkProtocol.magic)
        XCTAssertEqual(packet[0x24], 0x36)
        XCTAssertEqual(packet[0x25], 0x5f)
        XCTAssertEqual(packet[0x26], 0x6a)
        XCTAssertEqual(packet[0x28], 0x02)
        XCTAssertEqual(packet[0x29], 0x01)
        XCTAssertEqual(Array(packet[0x2a..<0x30]), mac)
        XCTAssertEqual(Array(packet[0x30..<0x34]), deviceID)

        let payloadChecksum = BroadlinkProtocol.checksum(payload)
        XCTAssertEqual(packet[0x34], UInt8(payloadChecksum & 0xff))
        XCTAssertEqual(packet[0x35], UInt8((payloadChecksum >> 8) & 0xff))

        XCTAssertEqual(packet.count, 0x38 + 16)   // header + one padded block

        var zeroed = packet
        zeroed[0x20] = 0
        zeroed[0x21] = 0
        let packetChecksum = BroadlinkProtocol.checksum(zeroed)
        XCTAssertEqual(packet[0x20], UInt8(packetChecksum & 0xff))
        XCTAssertEqual(packet[0x21], UInt8((packetChecksum >> 8) & 0xff))
    }

    func testParseResponseDecrypts() {
        let key = BroadlinkProtocol.defaultKey
        let payload: [UInt8] = Array(0..<16)
        let response = Self.makeResponse(error: 0, payload: payload, key: key)
        let (error, decoded) = BroadlinkProtocol.parseResponse([UInt8](response), key: key)
        XCTAssertEqual(error, 0)
        XCTAssertEqual(decoded, payload)
    }

    // MARK: - Auth

    func testAuthResponseRoundTrip() {
        let key = BroadlinkProtocol.defaultKey
        let deviceID: [UInt8] = [0xAA, 0xBB, 0xCC, 0xDD]
        let sessionKey: [UInt8] = (1...16).map { UInt8($0) }
        var payload = [UInt8](repeating: 0, count: 0x50)
        payload.replaceSubrange(0x00..<0x04, with: deviceID)
        payload.replaceSubrange(0x04..<0x14, with: sessionKey)

        let response = Self.makeResponse(error: 0, payload: payload, key: key)
        let (error, decoded) = BroadlinkProtocol.parseResponse([UInt8](response), key: key)
        XCTAssertEqual(error, 0)
        let auth = BroadlinkProtocol.parseAuth(payload: decoded)
        XCTAssertEqual(auth?.deviceID, deviceID)
        XCTAssertEqual(auth?.key, sessionKey)
    }

    // MARK: - IR payloads

    func testIRPayloadLayouts() {
        XCTAssertEqual(BroadlinkProtocol.sendIRPayload(code: [0xAB, 0xCD]), [0x02, 0, 0, 0, 0xAB, 0xCD])
        XCTAssertEqual(BroadlinkProtocol.enterLearningPayload(), [0x03, 0, 0, 0])
        XCTAssertEqual(BroadlinkProtocol.checkLearnedPayload(), [0x04, 0, 0, 0])
    }

    func testParseLearnedCode() {
        XCTAssertNil(BroadlinkProtocol.parseLearnedCode(payload: [0, 0, 0, 0]))
        XCTAssertEqual(BroadlinkProtocol.parseLearnedCode(payload: [0, 0, 0, 0, 0xAA, 0xBB]), [0xAA, 0xBB])
    }

    // MARK: - Discovery

    func testDiscoveryPacket() {
        let packet = BroadlinkProtocol.discoveryPacket(localIP: [192, 168, 1, 20], localPort: 0x1234)
        XCTAssertEqual(packet.count, 0x30)
        XCTAssertEqual(packet[0x26], 0x06)
        XCTAssertEqual(Array(packet[0x18..<0x1c]), [192, 168, 1, 20])
        XCTAssertEqual(packet[0x1c], 0x34)
        XCTAssertEqual(packet[0x1d], 0x12)

        var zeroed = packet
        zeroed[0x20] = 0
        zeroed[0x21] = 0
        let checksum = BroadlinkProtocol.checksum(zeroed)
        XCTAssertEqual(packet[0x20], UInt8(checksum & 0xff))
        XCTAssertEqual(packet[0x21], UInt8((checksum >> 8) & 0xff))
    }

    func testParseDiscovery() {
        var data = [UInt8](repeating: 0, count: 0x40)
        data[0x34] = 0x36
        data[0x35] = 0x5f
        let mac: [UInt8] = [0x11, 0x22, 0x33, 0x44, 0x55, 0x66]
        data.replaceSubrange(0x3a..<0x40, with: mac)
        let device = BroadlinkProtocol.parseDiscovery(data)
        XCTAssertEqual(device?.deviceType, 0x5f36)
        XCTAssertEqual(device?.mac, mac)
    }

    func testMacParsing() {
        XCTAssertEqual(BroadlinkDevice.mac(from: "11:22:33:44:55:66"), [0x11, 0x22, 0x33, 0x44, 0x55, 0x66])
        XCTAssertEqual(BroadlinkDevice.mac(from: "112233445566"), [0x11, 0x22, 0x33, 0x44, 0x55, 0x66])
        XCTAssertNil(BroadlinkDevice.mac(from: "nope"))
    }

    // MARK: - Transport actor (fake UDP channel)

    private static let sessionKey: [UInt8] = (1...16).map { UInt8($0) }
    private static let host = IRHost(address: "192.168.1.50", mac: "aa:bb:cc:dd:ee:ff", deviceType: 0x5f36)

    private static func authResponse() -> Data {
        var payload = [UInt8](repeating: 0, count: 0x50)
        payload.replaceSubrange(0x00..<0x04, with: [0xAA, 0xBB, 0xCC, 0xDD])
        payload.replaceSubrange(0x04..<0x14, with: sessionKey)
        return makeResponse(error: 0, payload: payload, key: BroadlinkProtocol.defaultKey)
    }

    func testTransportSendAuthenticatesThenSends() async throws {
        let channel = FakeUDPChannel(responses: [
            Self.authResponse(),
            Self.makeResponse(error: 0, payload: [], key: Self.sessionKey),   // send ack
        ])
        let transport = BroadlinkTransport(channel: channel, pollInterval: .milliseconds(1))
        let code = Data([0x26, 0x00, 0x04, 0x00]).base64EncodedString()

        try await transport.send(code: code, format: .broadlink, to: Self.host)

        let count = await channel.sentCount
        XCTAssertEqual(count, 2)   // auth + send, no discovery (mac/type provided)
    }

    func testTransportSendRejectsNonBroadlinkFormat() async {
        let transport = BroadlinkTransport(channel: FakeUDPChannel(responses: []))
        do {
            try await transport.send(code: "AAAA", format: .nec, to: Self.host)
            XCTFail("expected throw")
        } catch {
            guard case AppError.unsupportedIRFormat = error else {
                return XCTFail("expected unsupportedIRFormat, got \(error)")
            }
        }
    }

    func testTransportSendRejectsBadBase64() async {
        let transport = BroadlinkTransport(channel: FakeUDPChannel(responses: []))
        do {
            try await transport.send(code: "not base64!", format: .broadlink, to: Self.host)
            XCTFail("expected throw")
        } catch {
            guard case AppError.irSendFailed = error else {
                return XCTFail("expected irSendFailed, got \(error)")
            }
        }
    }

    func testTransportLearnReturnsCapturedCode() async throws {
        let codeBytes: [UInt8] = (1...12).map { UInt8($0) }   // 12 + 4 header = one block
        let learned = Self.makeResponse(error: 0, payload: [0, 0, 0, 0] + codeBytes, key: Self.sessionKey)
        let channel = FakeUDPChannel(responses: [
            Self.authResponse(),
            Self.makeResponse(error: 0, payload: [], key: Self.sessionKey),   // enter-learning ack
            learned,
        ])
        let transport = BroadlinkTransport(channel: channel, pollInterval: .milliseconds(1))

        let result = try await transport.learn(from: Self.host, timeout: .seconds(1))
        XCTAssertEqual(result, Data(codeBytes).base64EncodedString())
    }

    func testTransportLearnTimesOut() async {
        let stillWaiting = Self.makeResponse(error: -5, payload: [], key: Self.sessionKey)
        let channel = FakeUDPChannel(
            responses: [
                Self.authResponse(),
                Self.makeResponse(error: 0, payload: [], key: Self.sessionKey),   // enter-learning ack
                stillWaiting,
            ],
            repeatLast: true
        )
        let transport = BroadlinkTransport(channel: channel, pollInterval: .milliseconds(2))

        do {
            _ = try await transport.learn(from: Self.host, timeout: .milliseconds(40))
            XCTFail("expected throw")
        } catch {
            guard case AppError.irLearnTimedOut = error else {
                return XCTFail("expected irLearnTimedOut, got \(error)")
            }
        }
    }

    // MARK: - Helpers

    /// Frames a response the codec can parse: a 0x38 header carrying `error`,
    /// followed by AES(payload) under `key`.
    static func makeResponse(error: Int16, payload: [UInt8], key: [UInt8]) -> Data {
        var header = [UInt8](repeating: 0, count: 0x38)
        header[0x22] = UInt8(truncatingIfNeeded: error)
        header[0x23] = UInt8(truncatingIfNeeded: error >> 8)
        let encrypted = payload.isEmpty
            ? []
            : BroadlinkProtocol.aesEncrypt(BroadlinkProtocol.padToBlock(payload), key: key)
        return Data(header + encrypted)
    }
}

// MARK: - Fake UDP Channel

private actor FakeUDPChannel: UDPChannel {
    private var responses: [Data]
    private let repeatLast: Bool
    private var lastResponse: Data?
    private(set) var sentCount = 0

    init(responses: [Data], repeatLast: Bool = false) {
        self.responses = responses
        self.repeatLast = repeatLast
    }

    func exchange(_ data: Data, host: String, port: UInt16, timeout: Duration) async throws -> Data {
        sentCount += 1
        if !responses.isEmpty {
            lastResponse = responses.removeFirst()
            return lastResponse!
        }
        if repeatLast, let lastResponse { return lastResponse }
        throw URLError(.timedOut)
    }
}
