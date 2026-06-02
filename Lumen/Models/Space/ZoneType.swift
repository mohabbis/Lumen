//
//  ZoneType.swift
//  Muhome
//
//  Created by Muhammad Rafiq on 20/05/2026.
//

import Foundation

// MARK: - Zone Type
enum ZoneType: String, CaseIterable, Codable {
    case seatingArea = "Seating Area"
    case workspace = "Workspace"
    case mediaZone = "Media Zone"
    case diningArea = "Dining Area"
    case sleepingArea = "Sleeping Area"
    case entryZone = "Entry Zone"
    case custom = "Custom"
}