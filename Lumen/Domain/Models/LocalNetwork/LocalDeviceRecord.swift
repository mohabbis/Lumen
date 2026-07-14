import Foundation
import SwiftData

// MARK: - Local Device Record (@Model)
// The persisted authoring record for a local-network device. Turned into a
// value-type LocalDeviceConfig for the LocalNetworkBridge — the model never
// reaches the integration layer, matching the RemoteProfile → IRHost convention.

@Model
final class LocalDeviceRecord {
    var id: UUID
    var displayName: String
    var roomName: String?
    var address: String            // IP or hostname of the device on the LAN
    var kindRaw: String            // LocalDeviceKind
    var channel: Int               // component index (multi-relay devices)
    var categoryRaw: String        // DeviceCategory, for UI grouping
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        roomName: String? = nil,
        address: String,
        kind: LocalDeviceKind = .shellySwitch,
        channel: Int = 0,
        category: DeviceCategory = .lighting,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.roomName = roomName
        self.address = address
        self.kindRaw = kind.rawValue
        self.channel = channel
        self.categoryRaw = category.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    /// Device kind. Legacy/unknown rows fall back to a plain switch.
    var kind: LocalDeviceKind {
        get { LocalDeviceKind(rawValue: kindRaw) ?? .shellySwitch }
        set { kindRaw = newValue.rawValue }
    }

    /// UI grouping category. Unknown rows fall back to `.other`.
    var category: DeviceCategory {
        get { DeviceCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// The value-type config handed to the bridge.
    var config: LocalDeviceConfig {
        LocalDeviceConfig(
            id: id,
            displayName: displayName,
            roomName: roomName,
            host: LocalHost(address: address),
            kind: kind,
            channel: channel,
            category: category
        )
    }
}
