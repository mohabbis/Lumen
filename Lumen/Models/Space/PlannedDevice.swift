import Foundation
import SwiftData

// MARK: - Planned Device (@Model)
// Represents a device in the planning-through-commissioning lifecycle.
// Once commissioned, liveDeviceID links it to the in-memory DeviceStateStore entry.

@Model
final class PlannedDevice {
    var id: UUID
    var room: Room?
    var zone: Zone?
    var name: String
    var typeRaw: String
    var manufacturer: String?
    var model: String?
    var notes: String?
    var isInstalled: Bool
    var planningStageRaw: String
    var createdAt: Date
    var updatedAt: Date

    // Commissioning fields — set by DeviceService.commission(...)
    var liveDeviceID: UUID?          // Matches DeviceStateStore key after commissioning
    var bridgeIDRaw: String?         // BridgeID.rawValue of the owning bridge

    // Spatial — normalised within room coordinate space (0.0–1.0)
    var positionX: Double?
    var positionY: Double?

    init(
        id: UUID = UUID(),
        name: String,
        type: DeviceType,
        manufacturer: String? = nil,
        model: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.manufacturer = manufacturer
        self.model = model
        self.notes = notes
        self.isInstalled = false
        self.planningStageRaw = PlanningStage.planned.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var type: DeviceType {
        get { DeviceType(rawValue: typeRaw) ?? .light }
        set { typeRaw = newValue.rawValue }
    }

    var planningStage: PlanningStage {
        get { PlanningStage(rawValue: planningStageRaw) ?? .planned }
        set { planningStageRaw = newValue.rawValue }
    }

    var bridgeID: BridgeID? {
        bridgeIDRaw.map { BridgeID($0) }
    }

    var displayName: String {
        name.isEmpty ? type.displayName : name
    }

    var isCommissioned: Bool {
        liveDeviceID != nil
    }
}
