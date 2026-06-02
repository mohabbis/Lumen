//
//  MuhomeDataModels.swift
//  Muhome
//
//  Created by Muhammad Rafiq on 19/05/2026.
//  Copyright © 2026 Muhome. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - SwiftData Persistent Models

@Model
final class MuhaSceneRecord {
    var id: UUID
    var name: String
    var iconName: String
    var colorSwatchRaw: String
    var actionsData: Data            // JSON-encoded [SceneActionRecord]
    var isDefault: Bool
    var sortOrder: Int
    var lastActivated: Date?
    var activationCount: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorSwatchRaw: String,
        actionsData: Data = Data(),
        isDefault: Bool = false,
        sortOrder: Int = 0,
        lastActivated: Date? = nil,
        activationCount: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorSwatchRaw = colorSwatchRaw
        self.actionsData = actionsData
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.lastActivated = lastActivated
        self.activationCount = activationCount
        self.createdAt = createdAt
    }
}

@Model
final class MuhaRoomRecord {
    var id: String               // HMRoom UUID string
    var displayName: String
    var emoji: String
    var sortOrder: Int
    var iconOverride: String?    // SF Symbol override

    init(id: String, displayName: String, emoji: String = "🏠", sortOrder: Int = 0, iconOverride: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.iconOverride = iconOverride
    }
}

@Model
final class UserPreferencesRecord {
    var primaryHomeId: String?
    var userName: String
    var onboardingCompleted: Bool
    var hapticFeedbackEnabled: Bool
    var ambientModeEnabled: Bool
    var homekitEnabled: Bool
    var goveeEnabled: Bool
    var kasaEnabled: Bool
    var homebridgeEnabled: Bool
    var updatedAt: Date

    init(
        primaryHomeId: String? = nil,
        userName: String = "",
        onboardingCompleted: Bool = false,
        hapticFeedbackEnabled: Bool = true,
        ambientModeEnabled: Bool = true,
        homekitEnabled: Bool = false,
        goveeEnabled: Bool = false,
        kasaEnabled: Bool = false,
        homebridgeEnabled: Bool = false,
        updatedAt: Date = Date()
    ) {
        self.primaryHomeId = primaryHomeId
        self.userName = userName
        self.onboardingCompleted = onboardingCompleted
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.ambientModeEnabled = ambientModeEnabled
        self.homekitEnabled = homekitEnabled
        self.goveeEnabled = goveeEnabled
        self.kasaEnabled = kasaEnabled
        self.homebridgeEnabled = homebridgeEnabled
        self.updatedAt = updatedAt
    }
}

// MARK: - SceneAction Codable helper

struct SceneActionRecord: Codable {
    let deviceCombinedId: String
    let actionType: String       // "power" | "brightness" | "colorTemp" | "hue" | "sat"
    let value: Double
    let delaySeconds: Double
}
