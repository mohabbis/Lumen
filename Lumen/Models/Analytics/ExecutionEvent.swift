import Foundation
import SwiftData

// MARK: - Execution Event

@Model final class ExecutionEvent {
    var id: UUID
    var sceneID: UUID
    var sceneName: String       // denormalized: history survives scene deletion
    var timestamp: Date
    var succeededCount: Int
    var failedCount: Int
    var hourOfDay: Int           // 0–23, stored for fast time-of-day queries
    var dayOfWeek: Int           // 1–7 (Sun=1), Calendar.current.component(.weekday)

    init(sceneID: UUID, sceneName: String, succeeded: Int, failed: Int) {
        self.id = UUID()
        self.sceneID = sceneID
        self.sceneName = sceneName
        let now = Date()
        self.timestamp = now
        self.succeededCount = succeeded
        self.failedCount = failed
        let cal = Calendar.current
        self.hourOfDay = cal.component(.hour, from: now)
        self.dayOfWeek = cal.component(.weekday, from: now)
    }
}
