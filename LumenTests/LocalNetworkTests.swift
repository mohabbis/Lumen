import XCTest
@testable import Lumen

final class LocalNetworkTests: XCTestCase {

    // MARK: - Pure Shelly codec

    func testNormalizedBaseURLAcceptsBareHostPortAndURL() throws {
        XCTAssertEqual(try ShellyGen2Transport.normalizedBaseURL(from: "192.168.1.50").absoluteString, "http://192.168.1.50")
        XCTAssertEqual(try ShellyGen2Transport.normalizedBaseURL(from: "shelly.local:8080").absoluteString, "http://shelly.local:8080")
        XCTAssertEqual(try ShellyGen2Transport.normalizedBaseURL(from: "https://shelly.local").absoluteString, "https://shelly.local")
    }

    func testNormalizedBaseURLRejectsEmpty() {
        XCTAssertThrowsError(try ShellyGen2Transport.normalizedBaseURL(from: "  ")) { error in
            guard case AppError.invalidBridgeHostname = error else {
                return XCTFail("expected invalidBridgeHostname, got \(error)")
            }
        }
    }

    func testRelayPowerURL() throws {
        let base = try ShellyGen2Transport.normalizedBaseURL(from: "10.0.0.5")
        let target = LocalTarget(host: LocalHost(address: "10.0.0.5"), component: .relay, channel: 0)
        let url = try XCTUnwrap(ShellyGen2Transport.setURL(base: base, target: target, command: .power(true)))
        XCTAssertEqual(url.path, "/rpc/Switch.Set")
        XCTAssertEqual(Self.query(url), ["id": "0", "on": "true"])
    }

    func testLightBrightnessURLScalesToPercent() throws {
        let base = try ShellyGen2Transport.normalizedBaseURL(from: "10.0.0.5")
        let target = LocalTarget(host: LocalHost(address: "10.0.0.5"), component: .light, channel: 2)
        let url = try XCTUnwrap(ShellyGen2Transport.setURL(base: base, target: target, command: .brightness(0.4)))
        XCTAssertEqual(url.path, "/rpc/Light.Set")
        XCTAssertEqual(Self.query(url), ["id": "2", "brightness": "40"])
    }

    func testBrightnessOnRelayIsUnrepresentable() throws {
        let base = try ShellyGen2Transport.normalizedBaseURL(from: "10.0.0.5")
        let target = LocalTarget(host: LocalHost(address: "10.0.0.5"), component: .relay)
        XCTAssertNil(ShellyGen2Transport.setURL(base: base, target: target, command: .brightness(0.5)))
    }

    func testStatusURLPerComponent() throws {
        let base = try ShellyGen2Transport.normalizedBaseURL(from: "10.0.0.5")
        let relay = LocalTarget(host: LocalHost(address: "10.0.0.5"), component: .relay, channel: 1)
        let light = LocalTarget(host: LocalHost(address: "10.0.0.5"), component: .light, channel: 0)
        XCTAssertEqual(ShellyGen2Transport.statusURL(base: base, target: relay).path, "/rpc/Switch.GetStatus")
        XCTAssertEqual(Self.query(ShellyGen2Transport.statusURL(base: base, target: relay)), ["id": "1"])
        XCTAssertEqual(ShellyGen2Transport.statusURL(base: base, target: light).path, "/rpc/Light.GetStatus")
    }

    func testParseReading() {
        let light = ShellyGen2Transport.parseReading(data: Data(#"{"id":0,"output":true,"brightness":75}"#.utf8))
        XCTAssertEqual(light.isOn, true)
        XCTAssertEqual(light.brightness ?? 0, 0.75, accuracy: 0.0001)

        let relay = ShellyGen2Transport.parseReading(data: Data(#"{"id":0,"output":false}"#.utf8))
        XCTAssertEqual(relay.isOn, false)
        XCTAssertNil(relay.brightness)

        let garbage = ShellyGen2Transport.parseReading(data: Data("not json".utf8))
        XCTAssertNil(garbage.isOn)
        XCTAssertNil(garbage.brightness)
    }

    // MARK: - Device capabilities

    func testDimmerExposesOnOffAndBrightnessSwitchOnlyOnOff() {
        let transport = FakeLocalTransport()
        let dimmer = LocalNetworkDevice(config: Self.dimmerConfig, transport: transport)
        let toggle = LocalNetworkDevice(config: Self.switchConfig, transport: transport)

        XCTAssertTrue(dimmer.supports(.onOff))
        XCTAssertTrue(dimmer.supports(.brightness))
        XCTAssertTrue(toggle.supports(.onOff))
        XCTAssertFalse(toggle.supports(.brightness))
    }

    func testOnOffCapabilityReadsAndWritesThroughTransport() async throws {
        let transport = FakeLocalTransport(reading: LocalDeviceReading(isOn: true))
        let device = LocalNetworkDevice(config: Self.switchConfig, transport: transport)
        let onOff = try XCTUnwrap(device.capability(of: LocalNetworkOnOffCapability.self))

        let value = await onOff.isOn
        XCTAssertTrue(value)

        try await onOff.setPower(false)
        let applied = await transport.applied
        XCTAssertEqual(applied.map { $0.0 }, [.power(false)])
        XCTAssertEqual(applied.first?.1.component, .relay)
    }

    func testBrightnessCapabilityScalesRead() async throws {
        let transport = FakeLocalTransport(reading: LocalDeviceReading(isOn: true, brightness: 0.5))
        let device = LocalNetworkDevice(config: Self.dimmerConfig, transport: transport)
        let brightness = try XCTUnwrap(device.capability(of: LocalNetworkBrightnessCapability.self))

        let value = await brightness.brightness
        XCTAssertEqual(value, 0.5, accuracy: 0.0001)

        try await brightness.setBrightness(0.3)
        let applied = await transport.applied
        XCTAssertEqual(applied.map { $0.0 }, [.brightness(0.3)])
    }

    func testExecuteRoutesSnapshotToTransport() async throws {
        let transport = FakeLocalTransport()
        let device = LocalNetworkDevice(config: Self.dimmerConfig, transport: transport)

        try await device.execute(SceneActionSnapshot(deviceID: device.id, capabilityID: .onOff, payload: .bool(true)))
        try await device.execute(SceneActionSnapshot(deviceID: device.id, capabilityID: .brightness, payload: .double(0.8)))

        let applied = await transport.applied
        XCTAssertEqual(applied.map { $0.0 }, [.power(true), .brightness(0.8)])
    }

    func testExecuteRejectsUnsupportedCapability() async {
        let device = LocalNetworkDevice(config: Self.switchConfig, transport: FakeLocalTransport())
        do {
            try await device.execute(SceneActionSnapshot(deviceID: device.id, capabilityID: .lock, payload: .lockState(.locked)))
            XCTFail("expected throw")
        } catch {
            guard case AppError.capabilityNotSupported = error else {
                return XCTFail("expected capabilityNotSupported, got \(error)")
            }
        }
    }

    // MARK: - Bridge flow

    func testBridgeDiscoversConfiguredDevices() async throws {
        let transport = FakeLocalTransport(reading: LocalDeviceReading(isOn: false))
        let bridge = Self.bridge(configs: [Self.switchConfig, Self.dimmerConfig], transport: transport)

        try await bridge.authorize()
        let devices = try await bridge.discover()

        XCTAssertEqual(Set(devices.map(\.id)), [Self.switchConfig.id, Self.dimmerConfig.id])
        XCTAssertTrue(devices.allSatisfy { $0.bridgeID == .localNetwork })
        XCTAssertTrue(devices.allSatisfy { $0.reachability == .reachable })
    }

    func testBridgeMarksUnreachableWhenProbeFails() async throws {
        let transport = FakeLocalTransport(failReads: true)
        let bridge = Self.bridge(configs: [Self.switchConfig], transport: transport)

        try await bridge.authorize()
        let devices = try await bridge.discover()
        XCTAssertEqual(devices.first?.reachability, .unreachable)
    }

    func testBridgeExecuteActionRoutesAndEmits() async throws {
        let transport = FakeLocalTransport()
        let bridge = Self.bridge(configs: [Self.dimmerConfig], transport: transport)
        try await bridge.authorize()
        _ = try await bridge.discover()

        let stream = await bridge.deviceStateStream()
        try await bridge.executeAction(
            SceneActionSnapshot(deviceID: Self.dimmerConfig.id, capabilityID: .onOff, payload: .bool(true))
        )

        let applied = await transport.applied
        XCTAssertEqual(applied.map { $0.0 }, [.power(true)])

        var iterator = stream.makeAsyncIterator()
        let change = await iterator.next()
        XCTAssertEqual(change?.deviceID, Self.dimmerConfig.id)
        XCTAssertEqual(change?.capabilityID, .onOff)
    }

    func testBridgeExecuteUnknownDeviceThrows() async throws {
        let bridge = Self.bridge(configs: [], transport: FakeLocalTransport())
        try await bridge.authorize()
        do {
            try await bridge.executeAction(
                SceneActionSnapshot(deviceID: UUID(), capabilityID: .onOff, payload: .bool(true))
            )
            XCTFail("expected throw")
        } catch {
            guard case AppError.deviceNotFound = error else {
                return XCTFail("expected deviceNotFound, got \(error)")
            }
        }
    }

    func testBridgeDeviceLookup() async throws {
        let bridge = Self.bridge(configs: [Self.switchConfig], transport: FakeLocalTransport())
        try await bridge.authorize()
        _ = try await bridge.discover()

        let found = await bridge.device(withID: Self.switchConfig.id)
        XCTAssertEqual(found?.displayName, Self.switchConfig.displayName)
        let missing = await bridge.device(withID: UUID())
        XCTAssertNil(missing)
    }

    // MARK: - Fixtures

    static let switchConfig = LocalDeviceConfig(
        displayName: "Porch Relay",
        host: LocalHost(address: "10.0.0.5"),
        kind: .shellySwitch
    )

    static let dimmerConfig = LocalDeviceConfig(
        displayName: "Hallway Dimmer",
        host: LocalHost(address: "10.0.0.6"),
        kind: .shellyDimmer
    )

    static func bridge(configs: [LocalDeviceConfig], transport: FakeLocalTransport) -> LocalNetworkBridge {
        LocalNetworkBridge(configProvider: { configs }, transportFactory: { _ in transport })
    }

    static func query(_ url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }
}

// MARK: - Fake Local Transport

private actor FakeLocalTransport: LocalDeviceTransport {
    private let reading: LocalDeviceReading
    private let failReads: Bool
    private(set) var applied: [(LocalDeviceCommand, LocalTarget)] = []

    init(reading: LocalDeviceReading = LocalDeviceReading(), failReads: Bool = false) {
        self.reading = reading
        self.failReads = failReads
    }

    func apply(_ command: LocalDeviceCommand, to target: LocalTarget) async throws {
        applied.append((command, target))
    }

    func read(from target: LocalTarget) async throws -> LocalDeviceReading {
        if failReads { throw URLError(.cannotConnectToHost) }
        return reading
    }
}
