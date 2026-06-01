import Foundation
import SwiftData

// MARK: - IR Command (@Model)

@Model
final class IRCommand {
    var id: UUID
    var remote: RemoteProfile?
    var name: String
    var iconName: String
    var irCode: String              // Base64-encoded signal or Broadlink hex string
    var irFormatRaw: String
    var sortOrder: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "hand.tap",
        irCode: String,
        irFormat: IRFormat = .broadlink,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.irCode = irCode
        self.irFormatRaw = irFormat.rawValue
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }

    var irFormat: IRFormat {
        get { IRFormat(rawValue: irFormatRaw) ?? .broadlink }
        set { irFormatRaw = newValue.rawValue }
    }
}

// MARK: - IR Formats

enum IRFormat: String, Codable, CaseIterable {
    case broadlink = "broadlink"
    case pronto    = "pronto"
    case raw       = "raw"
    case nec       = "nec"
    case samsung   = "samsung"
}
