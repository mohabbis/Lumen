import Foundation
import SwiftData

// MARK: - Remote Profile (@Model)

@Model
final class RemoteProfile {
    var id: UUID
    var name: String
    var deviceBrand: String?
    var deviceModel: String?
    var iconName: String
    var bridgeHostname: String?   // IR blaster IP or hostname
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
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.deviceBrand = deviceBrand
        self.deviceModel = deviceModel
        self.iconName = iconName
        self.bridgeHostname = bridgeHostname
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
        self.commands = []
    }
}
