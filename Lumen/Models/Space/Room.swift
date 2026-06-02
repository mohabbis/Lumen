import Foundation
import SwiftData

@Model
final class Room {
    var id: UUID
    var home: Home?                 // Optional for SwiftData inverse relationship; semantically required
    var name: String
    var typeRaw: String
    var level: Int?
    var isAccessible: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PlannedDevice.room)
    var plannedDevices: [PlannedDevice]

    @Relationship(deleteRule: .cascade, inverse: \Zone.room)
    var zones: [Zone]

    init(
        id: UUID = UUID(),
        name: String,
        type: RoomType = .other,
        level: Int? = nil,
        isAccessible: Bool = true
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.level = level
        self.isAccessible = isAccessible
        self.createdAt = Date()
        self.updatedAt = Date()
        self.plannedDevices = []
        self.zones = []
    }

    var type: RoomType {
        get { RoomType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var deviceCount: Int { plannedDevices.count }

    var installedCount: Int { plannedDevices.filter { $0.isInstalled }.count }
}
