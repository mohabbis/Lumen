import Foundation
import SwiftData

// MARK: - Remote Transport Kind

enum RemoteTransportKind: String, Codable, CaseIterable, Sendable {
    case http
    case broadlink

    var displayName: String {
        switch self {
        case .http:      return "HTTP bridge"
        case .broadlink: return "Broadlink"
        }
    }
}

// MARK: - Remote Profile (@Model)

@Model
final class RemoteProfile {
    var id: UUID
    var name: String
    var deviceBrand: String?
    var deviceModel: String?
    var iconName: String
    var bridgeHostname: String?   // IR blaster IP or hostname

    // Transport selection + Broadlink hints. All nullable so SwiftData infers a
    // lightweight migration (no schema-version bump), the same as Home lat/long.
    var transportKindRaw: String?
    var broadlinkMAC: String?
    var broadlinkDeviceType: Int?

    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \IRCommand.remote)
    var commands: [IRCommand]

    init(
        id: UUID = UUID(),
        name: String,
        deviceBrand: String? = nil,
        deviceModel: String? = nil,
        iconName: String = "remote",
        bridgeHostname: String? = nil,
        transportKind: RemoteTransportKind = .http,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.deviceBrand = deviceBrand
        self.deviceModel = deviceModel
        self.iconName = iconName
        self.bridgeHostname = bridgeHostname
        self.transportKindRaw = transportKind.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
        self.commands = []
    }

    /// Transport used to reach this remote. Legacy rows with no stored value
    /// default to `.http`.
    var transportKind: RemoteTransportKind {
        get { transportKindRaw.flatMap(RemoteTransportKind.init(rawValue:)) ?? .http }
        set { transportKindRaw = newValue.rawValue }
    }
}
