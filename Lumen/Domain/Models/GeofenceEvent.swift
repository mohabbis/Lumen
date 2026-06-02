import Foundation

// MARK: - Geofence Event

struct GeofenceEvent: Sendable {
    enum EventType: Sendable {
        case arrival
        case departure
    }
    
    let type: EventType
    let timestamp: Date
    
    var displayName: String {
        switch type {
        case .arrival:
            return "Arrived home"
        case .departure:
            return "Left home"
        }
    }
}
