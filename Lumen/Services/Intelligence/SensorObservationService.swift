import Foundation
import Observation

// MARK: - Sensor Observation Service
// Subscribes to motion and contact capability streams on all capable devices.
// Maintains an in-memory ring buffer of recent events for use by inference layers.
// Never persisted — rebuilt from live bridge streams on each app launch.

@MainActor
@Observable
final class SensorObservationService {

    private(set) var recentMotionEvents: [MotionEvent] = []
    private(set) var recentContactEvents: [ContactEvent] = []

    private var sensorTasks: [String: Task<Void, Never>] = [:]
    private var activeKeys: Set<String> = []    // tracks live stream subscriptions per-capability

    private static let maxEvents = 200

    // MARK: - Observation

    func beginObserving(_ devices: [any SmartDevice]) {
        for device in devices {
            if let motionCap = device.capabilities.first(where: { $0 is any MotionCapability }) as? any MotionCapability {
                let key = "\(device.id)-motion"
                guard !activeKeys.contains(key) else { continue }
                activeKeys.insert(key)
                let id = device.id
                let room = device.roomName
                sensorTasks[key] = Task { [weak self] in
                    for await detected in motionCap.motionStream {
                        self?.record(MotionEvent(
                            deviceID: id,
                            roomName: room,
                            motionDetected: detected,
                            timestamp: Date()
                        ))
                    }
                    // Stream terminated — clear so beginObserving can re-subscribe
                    self?.deactivate(key: key)
                }
            }

            if let contactCap = device.capabilities.first(where: { $0 is any ContactCapability }) as? any ContactCapability {
                let key = "\(device.id)-contact"
                guard !activeKeys.contains(key) else { continue }
                activeKeys.insert(key)
                let id = device.id
                let room = device.roomName
                sensorTasks[key] = Task { [weak self] in
                    for await state in contactCap.contactStream {
                        self?.record(ContactEvent(
                            deviceID: id,
                            roomName: room,
                            state: state,
                            timestamp: Date()
                        ))
                    }
                    self?.deactivate(key: key)
                }
            }
        }
    }

    func cancelAll() {
        sensorTasks.values.forEach { $0.cancel() }
        sensorTasks.removeAll()
        activeKeys.removeAll()
    }

    func cancelObservations(forDeviceIDs deviceIDs: [DeviceID]) {
        for id in deviceIDs {
            for key in ["\(id)-motion", "\(id)-contact"] {
                sensorTasks[key]?.cancel()
                sensorTasks.removeValue(forKey: key)
                activeKeys.remove(key)
            }
        }
    }

    private func deactivate(key: String) {
        activeKeys.remove(key)
        sensorTasks.removeValue(forKey: key)
    }

    // MARK: - Private

    private func record(_ event: MotionEvent) {
        recentMotionEvents.append(event)
        if recentMotionEvents.count > Self.maxEvents {
            recentMotionEvents.removeFirst(recentMotionEvents.count - Self.maxEvents)
        }
    }

    private func record(_ event: ContactEvent) {
        recentContactEvents.append(event)
        if recentContactEvents.count > Self.maxEvents {
            recentContactEvents.removeFirst(recentContactEvents.count - Self.maxEvents)
        }
    }
}
