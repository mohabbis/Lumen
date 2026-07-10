import XCTest
@testable import Lumen

@MainActor
final class SceneActionBuilderTests: XCTestCase {

    private struct MockDevice: SmartDevice {
        let id: DeviceID
        let displayName: String
        let roomName: String? = nil
        let reachability: DeviceReachability = .reachable
        let bridgeID: BridgeID = .localPreview
        let category: DeviceCategory
        let capabilities: [any DeviceCapability]
    }

    func testEligibleDevicesFiltersReadOnlyOnlyDevices() {
        let controllable = MockDevice(
            id: UUID(),
            displayName: "Lamp",
            category: .lighting,
            capabilities: [
                LocalPreviewCapability(capabilityID: .onOff, displayName: "Power", isReadOnly: false),
            ]
        )
        let sensorOnly = MockDevice(
            id: UUID(),
            displayName: "Motion",
            category: .sensors,
            capabilities: [
                LocalPreviewCapability(capabilityID: .motion, displayName: "Motion", isReadOnly: true),
            ]
        )

        let eligible = SceneActionBuilder.eligibleDevices(from: [sensorOnly, controllable])
        XCTAssertEqual(eligible.count, 1)
        XCTAssertEqual(eligible.first?.displayName, "Lamp")
    }

    func testOptionsForDeviceReturnsSortedControllableCapabilities() {
        let device = MockDevice(
            id: UUID(),
            displayName: "Lamp",
            category: .lighting,
            capabilities: [
                LocalPreviewCapability(capabilityID: .brightness, displayName: "Brightness", isReadOnly: false),
                LocalPreviewCapability(capabilityID: .onOff, displayName: "Power", isReadOnly: false),
            ]
        )

        let options = SceneActionBuilder.options(for: device)
        XCTAssertEqual(options.map(\.displayName), ["Brightness", "Power"])
        XCTAssertEqual(options.first?.capabilityID, .brightness)
    }

    func testDefaultPayloadForLock() {
        let payload = SceneActionBuilder.defaultPayload(for: .lock)
        guard case .lockState(let state) = payload else {
            return XCTFail("Expected lock payload")
        }
        XCTAssertEqual(state, .locked)
    }
}
