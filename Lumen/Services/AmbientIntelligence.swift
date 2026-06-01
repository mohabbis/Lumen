//
//  AmbientIntelligence.swift
//  Muhome
//
//  Created by Muhammad Rafiq on 19/05/2026.
//  Copyright © 2026 Muhome. All rights reserved.
//

import Foundation
import Observation

// MARK: - Activation Record

struct SceneActivation: Codable {
    let sceneId: UUID
    let timestamp: Date

    var minuteOfDay: Int {
        let cal = Calendar.current
        return cal.component(.hour, from: timestamp) * 60 + cal.component(.minute, from: timestamp)
    }

    var isWeekend: Bool {
        let w = Calendar.current.component(.weekday, from: timestamp)
        return w == 1 || w == 7
    }
}

// MARK: - Suggestion

struct SceneSuggestion {
    let scene: MuhaScene
    let suggestedTime: String  // e.g. "7:15 PM"
    let pattern: String        // e.g. "weekdays" or "weekends"
}

// MARK: - AmbientIntelligence

@Observable
final class AmbientIntelligence {

    private(set) var suggestion: SceneSuggestion?

    private var log: [SceneActivation] = []
    private let logKey = "muhome.ambientIntelligence.activationLog"
    private let maxEntriesPerScene = 50
    private let minActivationsForSuggestion = 5
    private let maxSpreadMinutes = 45

    init() { loadLog() }

    // MARK: - Public

    func recordActivation(scene: MuhaScene) {
        log.append(SceneActivation(sceneId: scene.id, timestamp: Date()))
        trimLog(for: scene.id)
        saveLog()
        if let found = computeSuggestion(for: scene) {
            suggestion = found
        }
    }

    func dismissSuggestion() {
        suggestion = nil
    }

    // MARK: - Private

    private func computeSuggestion(for scene: MuhaScene) -> SceneSuggestion? {
        let entries = log.filter { $0.sceneId == scene.id }
        guard entries.count >= minActivationsForSuggestion else { return nil }

        for isWeekend in [false, true] {
            let group = entries.filter { $0.isWeekend == isWeekend }
            guard group.count >= minActivationsForSuggestion else { continue }

            let minutes = group.map(\.minuteOfDay)
            let mean = minutes.reduce(0, +) / minutes.count
            let spread = minutes.map { abs($0 - mean) }.max() ?? 0

            guard spread <= maxSpreadMinutes else { continue }

            return SceneSuggestion(
                scene: scene,
                suggestedTime: formatMinuteOfDay(mean),
                pattern: isWeekend ? "weekends" : "weekdays"
            )
        }
        return nil
    }

    private func trimLog(for sceneId: UUID) {
        var sceneEntries = log.indices.filter { log[$0].sceneId == sceneId }
        while sceneEntries.count > maxEntriesPerScene {
            log.remove(at: sceneEntries.removeFirst())
        }
    }

    private func formatMinuteOfDay(_ totalMinutes: Int) -> String {
        let hour = totalMinutes / 60
        let minute = totalMinutes % 60
        let h12 = hour % 12 == 0 ? 12 : hour % 12
        let suffix = hour < 12 ? "AM" : "PM"
        return String(format: "%d:%02d %@", h12, minute, suffix)
    }

    private func loadLog() {
        guard let data = UserDefaults.standard.data(forKey: logKey),
              let decoded = try? JSONDecoder().decode([SceneActivation].self, from: data) else { return }
        log = decoded
    }

    private func saveLog() {
        guard let data = try? JSONEncoder().encode(log) else { return }
        UserDefaults.standard.set(data, forKey: logKey)
    }
}
