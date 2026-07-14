import Foundation
import SwiftData

// MARK: - Geofence Trigger Type

enum GeofenceTrigger: String, Codable, CaseIterable, Sendable {
    case none
    case onArrival = "arrival"
    case onDeparture = "departure"
    
    var displayName: String {
        switch self {
        case .none: return "Never"
        case .onArrival: return "On Arrival"
        case .onDeparture: return "On Departure"
        }
    }
}

// MARK: - Scene (@Model)

@Model
final class Scene {
    var id: UUID
    var name: String
    var iconName: String
    var sortOrder: Int
    var isFavorite: Bool
    var geofenceTrigger: GeofenceTrigger
    // Daily schedule as minutes since local midnight (0…1439). `nil` means the
    // scene has no schedule. Optional, so SwiftData infers a lightweight
    // nullable-column migration (no schema-version bump), like Home.latitude.
    var scheduleMinutesSinceMidnight: Int?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SceneAction.scene)
    var actions: [SceneAction]

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "sparkles",
        sortOrder: Int = 0,
        geofenceTrigger: GeofenceTrigger = .none,
        scheduleMinutesSinceMidnight: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.sortOrder = sortOrder
        self.geofenceTrigger = geofenceTrigger
        self.scheduleMinutesSinceMidnight = scheduleMinutesSinceMidnight
        self.isFavorite = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.actions = []
    }

    /// The scene's schedule as (hour, minute), or nil when unscheduled.
    var scheduledTime: (hour: Int, minute: Int)? {
        guard let minutes = scheduleMinutesSinceMidnight, (0..<1440).contains(minutes) else { return nil }
        return (minutes / 60, minutes % 60)
    }

    func asSnapshots() -> [SceneActionSnapshot] {
        actions
            .sorted { $0.sortOrder < $1.sortOrder }
            .compactMap { $0.asSnapshot() }
    }
}

extension Scene: Identifiable {}
