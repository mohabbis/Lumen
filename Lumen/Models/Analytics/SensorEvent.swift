import Foundation

// MARK: - Sensor Events
// Value types collected in-memory by SensorObservationService.
// Not persisted — in-memory ring buffer only at this stage.

struct MotionEvent: Sendable {
    let deviceID: DeviceID
    let roomName: String?
    let motionDetected: Bool
    let timestamp: Date
}

struct ContactEvent: Sendable {
    let deviceID: DeviceID
    let roomName: String?
    let state: ContactState
    let timestamp: Date
}
