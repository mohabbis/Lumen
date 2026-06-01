import Foundation
import SwiftData

@Model
final class Home {
    var id: UUID
    var name: String
    var street: String?
    var city: String?
    var state: String?
    var zipCode: String?
    var country: String?
    var isPrimary: Bool
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Room.home)
    var rooms: [Room]

    @Relationship(deleteRule: .cascade, inverse: \Zone.home)
    var zones: [Zone]

    init(
        id: UUID = UUID(),
        name: String,
        street: String? = nil,
        city: String? = nil,
        state: String? = nil,
        zipCode: String? = nil,
        country: String? = nil,
        isPrimary: Bool = false
    ) {
        self.id = id
        self.name = name
        self.street = street
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.isPrimary = isPrimary
        self.createdAt = Date()
        self.updatedAt = Date()
        self.rooms = []
        self.zones = []
    }

    var roomCount: Int { rooms.count }

    var totalDeviceCount: Int { rooms.reduce(0) { $0 + $1.plannedDevices.count } }

    var installedDeviceCount: Int {
        rooms.reduce(0) { $0 + $1.plannedDevices.filter { $0.isInstalled }.count }
    }
}
