import Foundation
import SwiftData

@Model
final class Zone {
    var id: UUID
    var home: Home?                 // Top-level zone (not inside a room)
    var room: Room?                 // Sub-zone inside a room
    var name: String
    var typeRaw: String
    var positionX: Double?          // Normalised 0.0–1.0 within parent coordinate space
    var positionY: Double?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: ZoneType = .custom,
        positionX: Double? = nil,
        positionY: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.positionX = positionX
        self.positionY = positionY
        self.createdAt = Date()
    }

    var type: ZoneType {
        get { ZoneType(rawValue: typeRaw) ?? .custom }
        set { typeRaw = newValue.rawValue }
    }
}
