import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Request Permissions
    
    func requestNotificationPermissions() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("Notification permission request failed: \(error)")
            return false
        }
    }
    
    // MARK: - Send Notifications
    
    func notifyAutomationExecuted(sceneName: String, eventType: String, deviceCount: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Lumen — Automation Executed"
        
        // Customize message based on event type
        switch eventType {
        case "arrival":
            content.subtitle = "You arrived home"
            content.body = "'\(sceneName)' scene activated for \(deviceCount) device\(deviceCount == 1 ? "" : "s")"
        case "departure":
            content.subtitle = "You left home"
            content.body = "'\(sceneName)' scene activated for \(deviceCount) device\(deviceCount == 1 ? "" : "s")"
        case "schedule":
            content.subtitle = "Ran on schedule"
            content.body = "'\(sceneName)' ran on schedule — you set this up. Tap to adjust."
        default:
            content.body = "'\(sceneName)' scene activated"
        }
        
        content.sound = .default

        // Add custom data
        content.userInfo = [
            "sceneName": sceneName,
            "eventType": eventType,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Send notification after 1 second delay (feels natural)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send notification: \(error)")
            } else {
                print("Notification scheduled: \(sceneName)")
            }
        }
    }
    
    func notifyAutomationFailed(sceneName: String, reason: String) {
        let content = UNMutableNotificationContent()
        content.title = "Automation Failed"
        content.subtitle = sceneName
        content.body = reason
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send error notification: \(error)")
            }
        }
    }
    
    /// Notify user before an automated transition happens (for sensory profile transition warnings)
    func notifyUpcomingTransition(sceneName: String, minutesUntil: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Lumen — Upcoming Change"
        content.subtitle = "In \(minutesUntil) minutes"
        content.body = "'\(sceneName)' will activate soon. You can adjust or postpone in the app."
        content.sound = .default
        
        // Add custom data for deep linking
        content.userInfo = [
            "sceneName": sceneName,
            "eventType": "upcoming_transition",
            "minutesUntil": minutesUntil,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        // Schedule notification to fire at the warning time
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutesUntil * 60), repeats: false)
        let request = UNNotificationRequest(identifier: "transition_\(UUID().uuidString)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule transition warning: \(error)")
            } else {
                print("Transition warning scheduled: \(sceneName) in \(minutesUntil) min")
            }
        }
    }
    
    // MARK: - Clear Notifications

    func clearBadge() {
        Task { try? await UNUserNotificationCenter.current().setBadgeCount(0) }
    }
}
