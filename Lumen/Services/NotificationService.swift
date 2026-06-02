import Foundation
import UIKit
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
        default:
            content.body = "'\(sceneName)' scene activated"
        }
        
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
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
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to send error notification: \(error)")
            }
        }
    }
    
    // MARK: - Clear Notifications
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
