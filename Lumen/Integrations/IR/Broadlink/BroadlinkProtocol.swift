import Foundation
import CommonCrypto

// MARK: - Broadlink Protocol Codec
//
// Pure, side-effect-free encoders/decoders for the Broadlink RM UDP protocol
// (port 80). Mirrors the well-documented `python-broadlink` framing so the
// wire format is unit-testable without a socket or a real device. The actor
// (BroadlinkTransport) drives these over a UDPChannel.
//
// Packet framing (0x38-byte header + AES-encrypted payload):
//   0x00..0x07  magic 5a a5 aa 55 5a a5 aa 55
//   0x20..0x21  checksum over the WHOLE packet (with encrypted payload)
//   0x24..0x25  device type (little-endian)
//   0x26        command (0x65 auth, 0x6a normal)
//   0x28..0x29  packet counter (little-endian)
//   0x2a..0x2f  device MAC (6 bytes, as discovered)
//   0x30..0x33  device id (4 bytes, from auth; zero before auth)
//   0x34..0x35  checksum over the UNENCRYPTED payload (little-endian)
//   0x38..      AES-128-CBC(payload)
// Checksum: (0xBEAF + Σ bytes) & 0xFFFF.

enum BroadlinkProtocol {

    // MARK: Constants

    /// Initial AES key used for discovery/auth before a session key is issued.
    static let defaultKey: [UInt8] = [
        0x09, 0x76, 0x28, 0x34, 0x3f, 0xe9, 0x9e, 0x23,
        0x76, 0x5c, 0x15, 0x13, 0xac, 0xcf, 0x8b, 0x02,
    ]

    /// Fixed AES IV used for all Broadlink traffic.
    static let iv: [UInt8] = [
        0x56, 0x2e, 0x17, 0x99, 0x6d, 0x09, 0x3d, 0x28,
        0xdd, 0xb3, 0xba, 0x69, 0x5a, 0x2e, 0x6f, 0x58,
    ]

    static let magic: [UInt8] = [0x5a, 0xa5, 0xaa, 0x55, 0x5a, 0xa5, 0xaa, 0x55]

    enum Command {
        static let auth: UInt8 = 0x65
        static let normal: UInt8 = 0x6a
    }

    /// Sub-commands carried in a normal (0x6a) packet's payload header byte.
    enum IRSubcommand {
        static let sendData: UInt8 = 0x02
        static let enterLearning: UInt8 = 0x03
        static let checkLearned: UInt8 = 0x04
    }

    // MARK: Checksum

    static func checksum(_ bytes: [UInt8]) -> UInt16 {
        var sum = 0xBEAF
        for b in bytes { sum = (sum + Int(b)) & 0xFFFF }
        return UInt16(sum)
    }

    // MARK: AES-128-CBC (no padding; inputs are block-aligned)

    static func aesEncrypt(_ data: [UInt8], key: [UInt8]) -> [UInt8] {
        crypt(operation: CCOperation(kCCEncrypt), data: data, key: key)
    }

    static func aesDecrypt(_ data: [UInt8], key: [UInt8]) -> [UInt8] {
        crypt(operation: CCOperation(kCCDecrypt), data: data, key: key)
    }

    private static func crypt(operation: CCOperation, data: [UInt8], key: [UInt8]) -> [UInt8] {
        var out = [UInt8](repeating: 0, count: data.count + kCCBlockSizeAES128)
        var moved = 0
        _ = key.withUnsafeBytes { keyPtr in
            iv.withUnsafeBytes { ivPtr in
                data.withUnsafeBytes { dataPtr in
                    out.withUnsafeMutableBytes { outPtr in
                        CCCrypt(
                            operation,
                            CCAlgorithm(kCCAlgorithmAES128),
                            CCOptions(0),                 // no padding; CBC
                            keyPtr.baseAddress, key.count,
                            ivPtr.baseAddress,
                            dataPtr.baseAddress, data.count,
                            outPtr.baseAddress, out.count,
                            &moved
                        )
                    }
                }
            }
        }
        return Array(out.prefix(moved))
    }

    // MARK: Packet framing

    /// Frames a command packet: header + AES(payload), with both checksums set.
    static func buildPacket(
        command: UInt8,
        payload: [UInt8],
        mac: [UInt8],
        deviceType: Int,
        counter: UInt16,
        deviceID: [UInt8],
        key: [UInt8]
    ) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 0x38)
        packet.replaceSubrange(0x00..<0x08, with: magic)
        packet[0x24] = UInt8(deviceType & 0xff)
        packet[0x25] = UInt8((deviceType >> 8) & 0xff)
        packet[0x26] = command
        packet[0x28] = UInt8(counter & 0xff)
        packet[0x29] = UInt8((counter >> 8) & 0xff)
        if mac.count == 6 { packet.replaceSubrange(0x2a..<0x30, with: mac) }
        if deviceID.count == 4 { packet.replaceSubrange(0x30..<0x34, with: deviceID) }

        let payloadChecksum = checksum(payload)
        packet[0x34] = UInt8(payloadChecksum & 0xff)
        packet[0x35] = UInt8((payloadChecksum >> 8) & 0xff)

        packet.append(contentsOf: aesEncrypt(padToBlock(payload), key: key))

        let packetChecksum = checksum(packet)
        packet[0x20] = UInt8(packetChecksum & 0xff)
        packet[0x21] = UInt8((packetChecksum >> 8) & 0xff)
        return packet
    }

    /// Reads the response error code and decrypts the payload with `key`.
    static func parseResponse(_ data: [UInt8], key: [UInt8]) -> (errorCode: Int16, payload: [UInt8]) {
        guard data.count >= 0x38 else { return (-1, []) }
        let error = Int16(data[0x22]) | (Int16(data[0x23]) << 8)
        let encrypted = Array(data[0x38...])
        let payload = encrypted.isEmpty ? [] : aesDecrypt(encrypted, key: key)
        return (error, payload)
    }

    // MARK: Auth (0x65)

    /// The 0x50-byte auth payload. Encrypted with the default key; the response
    /// carries the device id + session key.
    static func authPayload(deviceName: String = "Lumen") -> [UInt8] {
        var payload = [UInt8](repeating: 0, count: 0x50)
        for i in 0x04...0x12 { payload[i] = 0x31 }   // placeholder id ("1"s)
        payload[0x1e] = 0x01
        payload[0x2d] = 0x01
        let name = Array(deviceName.utf8.prefix(0x1f))
        payload.replaceSubrange(0x30..<(0x30 + name.count), with: name)
        return payload
    }

    static func parseAuth(payload: [UInt8]) -> (deviceID: [UInt8], key: [UInt8])? {
        guard payload.count >= 0x14 else { return nil }
        let deviceID = Array(payload[0x00..<0x04])
        let key = Array(payload[0x04..<0x14])
        return (deviceID, key)
    }

    // MARK: IR payloads (carried in a 0x6a packet)

    static func sendIRPayload(code: [UInt8]) -> [UInt8] {
        [IRSubcommand.sendData, 0x00, 0x00, 0x00] + code
    }

    static func enterLearningPayload() -> [UInt8] {
        [IRSubcommand.enterLearning, 0x00, 0x00, 0x00]
    }

    static func checkLearnedPayload() -> [UInt8] {
        [IRSubcommand.checkLearned, 0x00, 0x00, 0x00]
    }

    /// Extracts the captured IR code from a check-learned response payload.
    /// The device returns an empty/short payload until a code is captured.
    static func parseLearnedCode(payload: [UInt8]) -> [UInt8]? {
        guard payload.count > 0x04 else { return nil }
        let code = Array(payload[0x04...])
        return code.isEmpty ? nil : code
    }

    // MARK: Discovery (hello)

    /// Builds the discovery/hello datagram. Broadcast to find devices, or
    /// unicast to a known IP to learn its MAC + device type.
    static func discoveryPacket(localIP: [UInt8], localPort: UInt16, now: Date = Date()) -> [UInt8] {
        var packet = [UInt8](repeating: 0, count: 0x30)

        // Local timezone offset (seconds) as little-endian int32 at 0x08.
        let tzSeconds = Int32(TimeZone.current.secondsFromGMT(for: now))
        packet[0x08] = UInt8(truncatingIfNeeded: tzSeconds)
        packet[0x09] = UInt8(truncatingIfNeeded: tzSeconds >> 8)
        packet[0x0a] = UInt8(truncatingIfNeeded: tzSeconds >> 16)
        packet[0x0b] = UInt8(truncatingIfNeeded: tzSeconds >> 24)

        let cal = Calendar(identifier: .gregorian)
        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekday], from: now)
        let year = c.year ?? 2026
        packet[0x0c] = UInt8(year & 0xff)
        packet[0x0d] = UInt8((year >> 8) & 0xff)
        packet[0x0e] = UInt8(c.minute ?? 0)
        packet[0x0f] = UInt8(c.hour ?? 0)
        packet[0x10] = UInt8((year % 100))
        // Calendar weekday is 1=Sun..7=Sat; Broadlink wants 1=Mon..7=Sun.
        packet[0x11] = UInt8(((( (c.weekday ?? 1) + 5) % 7) + 1))
        packet[0x12] = UInt8(c.day ?? 1)
        packet[0x13] = UInt8(c.month ?? 1)

        if localIP.count == 4 { packet.replaceSubrange(0x18..<0x1c, with: localIP) }
        packet[0x1c] = UInt8(localPort & 0xff)
        packet[0x1d] = UInt8((localPort >> 8) & 0xff)
        packet[0x26] = 0x06

        let sum = checksum(packet)
        packet[0x20] = UInt8(sum & 0xff)
        packet[0x21] = UInt8((sum >> 8) & 0xff)
        return packet
    }

    static func parseDiscovery(_ data: [UInt8]) -> BroadlinkDevice? {
        guard data.count >= 0x40 else { return nil }
        let deviceType = Int(data[0x34]) | (Int(data[0x35]) << 8)
        let mac = Array(data[0x3a..<0x40])   // stored as received
        return BroadlinkDevice(mac: mac, deviceType: deviceType)
    }

    // MARK: Helpers

    /// Pads to the next 16-byte boundary with zeros (Broadlink uses zero-fill,
    /// not PKCS#7).
    static func padToBlock(_ bytes: [UInt8]) -> [UInt8] {
        let remainder = bytes.count % 16
        guard remainder != 0 else { return bytes }
        return bytes + [UInt8](repeating: 0, count: 16 - remainder)
    }
}

// MARK: - Broadlink Device

struct BroadlinkDevice: Sendable, Equatable {
    let mac: [UInt8]
    let deviceType: Int

    var macString: String {
        mac.map { String(format: "%02x", $0) }.joined(separator: ":")
    }

    /// Parses "aa:bb:cc:dd:ee:ff" (or without separators) into 6 bytes.
    static func mac(from string: String) -> [UInt8]? {
        let hex = string.replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
        guard hex.count == 12 else { return nil }
        var bytes: [UInt8] = []
        var idx = hex.startIndex
        while idx < hex.endIndex {
            let next = hex.index(idx, offsetBy: 2)
            guard let byte = UInt8(hex[idx..<next], radix: 16) else { return nil }
            bytes.append(byte)
            idx = next
        }
        return bytes
    }
}
